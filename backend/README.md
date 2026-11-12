# Halal Assistant backend

FastAPI + SQLite + SQLAlchemy. See the [project README](../README.md) for the
full picture.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

- API documentation: http://localhost:8000/docs
- Tests: `pytest`
- Database: `halal_assistant.db` in this directory, created automatically.
  Set `HALAL_DB_PATH` to store it elsewhere.
- Ingredient knowledge database: `app/data/ingredients.json`, loaded into the
  `ingredients` table on every start.
