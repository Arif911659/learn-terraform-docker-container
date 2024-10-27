# main.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import uvicorn
from datetime import datetime
import sqlite3
import os

app = FastAPI(title="COVID-19 Tracking API")

# Data models
class CovidCase(BaseModel):
    country: str
    cases: int
    deaths: int
    recovered: int
    date: str

class CovidCaseInput(BaseModel):
    country: str
    cases: int
    deaths: int
    recovered: int

# Database initialization
def init_db():
    conn = sqlite3.connect('covid.db')
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS covid_cases
        (country TEXT, cases INTEGER, deaths INTEGER, 
         recovered INTEGER, date TEXT)
    ''')
    conn.commit()
    conn.close()

# API Routes
@app.on_event("startup")
async def startup_event():
    init_db()

@app.get("/")
async def root():
    return {"message": "COVID-19 Tracking API"}

@app.post("/cases/", response_model=CovidCase)
async def add_case(case: CovidCaseInput):
    conn = sqlite3.connect('covid.db')
    c = conn.cursor()
    
    current_date = datetime.now().strftime("%Y-%m-%d")
    c.execute(
        "INSERT INTO covid_cases VALUES (?, ?, ?, ?, ?)",
        (case.country, case.cases, case.deaths, case.recovered, current_date)
    )
    
    conn.commit()
    conn.close()
    
    return CovidCase(
        country=case.country,
        cases=case.cases,
        deaths=case.deaths,
        recovered=case.recovered,
        date=current_date
    )

@app.get("/cases/", response_model=List[CovidCase])
async def get_cases(country: Optional[str] = None):
    conn = sqlite3.connect('covid.db')
    c = conn.cursor()
    
    if country:
        c.execute("SELECT * FROM covid_cases WHERE country=?", (country,))
    else:
        c.execute("SELECT * FROM covid_cases")
        
    cases = []
    for row in c.fetchall():
        cases.append(CovidCase(
            country=row[0],
            cases=row[1],
            deaths=row[2],
            recovered=row[3],
            date=row[4]
        ))
    
    conn.close()
    return cases

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)