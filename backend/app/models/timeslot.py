from sqlalchemy import Column, Integer, String, Time
from app.database import Base

class TimeSlot(Base):
    __tablename__ = "timeslots"
    id = Column(Integer, primary_key=True, index=True)
    slot_name = Column(String, nullable=False)  # e.g., "Lunch 12-1"
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)