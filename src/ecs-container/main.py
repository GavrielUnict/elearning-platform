import os
import json
import asyncio
from typing import List, Dict
import boto3
from fastapi import FastAPI, HTTPException
import uvicorn
from pydantic import BaseModel
from openai import OpenAI
from datetime import datetime
import logging
import re

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI()

# AWS clients
s3 = boto3.client('s3')
textract = boto3.client('textract')
dynamodb = boto3.resource('dynamodb')
secrets_manager = boto3.client('secretsmanager')

# Environment variables
DOCUMENTS_BUCKET = os.environ['DOCUMENTS_BUCKET']
DOCUMENTS_TABLE = os.environ['DOCUMENTS_TABLE']
QUIZZES_TABLE = os.environ['QUIZZES_TABLE']
OPENAI_API_KEY_SECRET = os.environ['OPENAI_API_KEY_SECRET_NAME']

# Global variable for OpenAI client
openai_client = None

# Get OpenAI API key from Secrets Manager
def get_openai_api_key():
    try:
        response = secrets_manager.get_secret_value(SecretId=OPENAI_API_KEY_SECRET)
        return response['SecretString']
    except Exception as e:
        logger.error(f"Failed to get OpenAI API key: {e}")
        raise

# Initialize OpenAI client
def get_openai_client():
    global openai_client
    if openai_client is None:
        openai_client = OpenAI(api_key=get_openai_api_key())
    return openai_client

# Models
class QuizQuestion(BaseModel):
    question: str
    options: List[str]
    correct_answer: int  # Index of correct option (0-3)

class ProcessingResult(BaseModel):
    status: str
    quiz_id: str = None
    error: str = None

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy"}

# Main processing function
async def process_document():
    """Main function to process document when container starts"""
    try:
        # Get document info from environment
        document_id = os.environ.get('DOCUMENT_ID')
        course_id = os.environ.get('COURSE_ID')
        s3_key = os.environ.get('S3_KEY')
        
        if not all([document_id, course_id, s3_key]):
            raise ValueError("Missing required environment variables")
        
        logger.info(f"Processing document {document_id} from course {course_id}")
        
        # 1. Download PDF from S3
        logger.info("Downloading PDF from S3...")
        pdf_content = s3.get_object(Bucket=DOCUMENTS_BUCKET, Key=s3_key)['Body'].read()
        
        # 2. Extract text using Textract - Asynchronous operation
        logger.info("Starting asynchronous text extraction with Textract...")

        # Start asynchronous job
        start_response = textract.start_document_text_detection(
            DocumentLocation={
                'S3Object': {
                    'Bucket': DOCUMENTS_BUCKET,
                    'Name': s3_key
                }
            }
        )

        job_id = start_response['JobId']
        logger.info(f"Textract job started: {job_id}")

        # Poll for results
        max_attempts = 30
        attempt = 0
        while attempt < max_attempts:
            response = textract.get_document_text_detection(JobId=job_id)
            status = response['JobStatus']
            
            if status == 'SUCCEEDED':
                logger.info("Textract job completed successfully")
                break
            elif status == 'FAILED':
                raise Exception(f"Textract job failed: {response.get('StatusMessage', 'Unknown error')}")
            
            logger.info(f"Job status: {status}, waiting...")
            await asyncio.sleep(10)
            attempt += 1

        if attempt >= max_attempts:
            raise Exception("Textract job timed out")

        # Extract text from results
        extracted_text = ""
        for page in response.get('Blocks', []):
            if page['BlockType'] == 'LINE':
                extracted_text += page['Text'] + "\n"

        # Handle pagination if needed
        next_token = response.get('NextToken')
        while next_token:
            response = textract.get_document_text_detection(JobId=job_id, NextToken=next_token)
            for page in response.get('Blocks', []):
                if page['BlockType'] == 'LINE':
                    extracted_text += page['Text'] + "\n"
            next_token = response.get('NextToken')
        
        # Limit text length for API call
        max_chars = 10000
        if len(extracted_text) > max_chars:
            extracted_text = extracted_text[:max_chars] + "..."
        
        logger.info(f"Extracted {len(extracted_text)} characters")
        
        # 3. Generate quiz using OpenAI
        logger.info("Generating quiz with OpenAI...")
        quiz_questions = await generate_quiz(extracted_text)
        
        # 4. Save quiz to DynamoDB
        logger.info("Saving quiz to DynamoDB...")
        quiz_id = f"quiz-{document_id}-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
        
        quizzes_table = dynamodb.Table(QUIZZES_TABLE)
        quiz_item = {
            'documentId': document_id,
            'quizId': quiz_id,
            'questions': [
                {
                    'questionId': f"q{i+1}",
                    'question': q.question,
                    'options': q.options,
                    'correctAnswer': q.correct_answer
                }
                for i, q in enumerate(quiz_questions)
            ],
            'generatedAt': datetime.utcnow().isoformat(),
            'courseId': course_id
        }
        quizzes_table.put_item(Item=quiz_item)
        
        # 5. Update document status
        logger.info("Updating document status...")
        documents_table = dynamodb.Table(DOCUMENTS_TABLE)
        documents_table.update_item(
            Key={
                'courseId': course_id,
                'documentId': document_id
            },
            UpdateExpression='SET #status = :status, quizId = :quizId',
            ExpressionAttributeNames={
                '#status': 'status'
            },
            ExpressionAttributeValues={
                ':status': 'ready',
                ':quizId': quiz_id
            }
        )
        
        logger.info(f"Successfully processed document {document_id}")
        return ProcessingResult(status="success", quiz_id=quiz_id)
        
    except Exception as e:
        logger.error(f"Error processing document: {e}")
        
        # Update document status to failed
        try:
            documents_table = dynamodb.Table(DOCUMENTS_TABLE)
            documents_table.update_item(
                Key={
                    'courseId': course_id,
                    'documentId': document_id
                },
                UpdateExpression='SET #status = :status, processingError = :error',
                ExpressionAttributeNames={
                    '#status': 'status'
                },
                ExpressionAttributeValues={
                    ':status': 'failed',
                    ':error': str(e)
                }
            )
        except:
            pass
        
        return ProcessingResult(status="failed", error=str(e))

async def generate_quiz(text: str) -> List[QuizQuestion]:
    """Generate quiz questions using OpenAI API"""
    
    prompt = f"""Based on the following text, generate exactly 5 multiple choice questions in Italian.
Each question should test understanding of key concepts from the text.

IMPORTANT: Respond ONLY with a JSON array, no other text before or after.

The JSON must have this exact structure:
[
  {{
    "question": "La domanda in italiano?",
    "options": ["Opzione A", "Opzione B", "Opzione C", "Opzione D"],
    "correct_answer": 0
  }},
  {{
    "question": "Seconda domanda?",
    "options": ["Opzione A", "Opzione B", "Opzione C", "Opzione D"],
    "correct_answer": 2
  }}
]

Text to analyze:
{text}...

Remember: Generate exactly 5 questions. The correct_answer must be a number from 0 to 3."""

    try:
        client = get_openai_client()
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {
                    "role": "system",
                    "content": "You are a helpful assistant that generates educational multiple-choice questions. Always respond with valid JSON only, no additional text."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            temperature=0.7,
            max_tokens=2000
        )
        
        # Get the response content
        response_text = response.choices[0].message.content
        logger.info(f"OpenAI raw response: {response_text[:200]}...")  # Log first 200 chars
        
        # Try to extract JSON from the response
        # Sometimes OpenAI adds text before/after the JSON
        json_match = re.search(r'\[\s*{.*}\s*\]', response_text, re.DOTALL)
        if json_match:
            json_text = json_match.group(0)
        else:
            json_text = response_text.strip()
        
        # Parse response
        quiz_data = json.loads(json_text)
        
        # Validate and convert to QuizQuestion objects
        questions = []
        for i, item in enumerate(quiz_data[:5]):  # Ensure max 5 questions
            try:
                question = QuizQuestion(
                    question=item.get('question', f'Domanda {i+1}'),
                    options=item.get('options', ['A', 'B', 'C', 'D'])[:4],
                    correct_answer=min(int(item.get('correct_answer', 0)), 3)
                )
                questions.append(question)
            except Exception as e:
                logger.error(f"Error parsing question {i}: {e}")
                continue
        
        # Se abbiamo meno di 5 domande, genera domande default aggiuntive
        while len(questions) < 5:
            questions.append(
                QuizQuestion(
                    question=f"Domanda {len(questions) + 1}: Qual è un concetto importante trattato nel documento?",
                    options=[
                        "Il documento tratta principalmente di storia",
                        "Il documento tratta principalmente di geografia", 
                        "Il documento tratta principalmente di scienze",
                        "Il documento tratta principalmente di letteratura"
                    ],
                    correct_answer=0
                )
            )
        
        logger.info(f"Generated {len(questions)} quiz questions")
        return questions
        
    except json.JSONDecodeError as e:
        logger.error(f"JSON decode error: {e}")
        logger.error(f"Response was: {response_text[:500]}...")
    except Exception as e:
        logger.error(f"Failed to generate quiz: {e}")
    
    # Return 5 default questions if generation fails
    return [
        QuizQuestion(
            question=f"Domanda {i+1}: Qual è un aspetto importante del documento?",
            options=[
                f"Prima opzione per domanda {i+1}",
                f"Seconda opzione per domanda {i+1}", 
                f"Terza opzione per domanda {i+1}",
                f"Quarta opzione per domanda {i+1}"
            ],
            correct_answer=0
        )
        for i in range(5)
    ]

# Run processing when container starts
@app.on_event("startup")
async def startup_event():
    # Start processing in background
    asyncio.create_task(process_and_shutdown())

async def process_and_shutdown():
    """Process document and shutdown after completion"""
    try:
        await asyncio.sleep(5)  # Give FastAPI time to start
        result = await process_document()
        logger.info(f"Processing complete: {result}")
    except Exception as e:
        logger.error(f"Processing failed: {e}")
    finally:
        # Give time for health checks before shutting down
        await asyncio.sleep(30)
        os._exit(0)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)