from typing import Dict, List
from pydantic import BaseModel


class LearningDigest(BaseModel):
    month: str
    total: int
    by_type: Dict[str, int]
    by_root_cause_category: Dict[str, int]
    top_recurring: List[str]
    corrective_summaries: List[str]


class TrendBucket(BaseModel):
    by_department: Dict[str, int]
    by_type: Dict[str, int]
    by_source: Dict[str, int]
    by_time_bucket: Dict[str, int]
