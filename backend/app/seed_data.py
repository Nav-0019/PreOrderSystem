from app.database import SessionLocal
from app.models.user import User, UserRole
from app.models.menu import Menu
from app.models.timeslot import TimeSlot

db = SessionLocal()

# Users
admin = User(name="Admin", email="admin@college.com", password="hashed_password", role=UserRole.ADMIN)
baker1 = User(name="Baker 1", email="baker1@college.com", password="hashed_password", role=UserRole.BAKER)
customer1 = User(name="Student 1", email="student1@college.com", password="hashed_password", role=UserRole.CUSTOMER)

db.add_all([admin, baker1, customer1])
db.commit()

# Menu
menu1 = Menu(name="Veg Sandwich", description="Tasty Veg Sandwich", price=50, available_quantity=100, baker_id=baker1.id)
menu2 = Menu(name="Chicken Roll", description="Spicy Chicken Roll", price=80, available_quantity=50, baker_id=baker1.id)
db.add_all([menu1, menu2])
db.commit()

# TimeSlots
import datetime
slot1 = TimeSlot(start_time=datetime.time(12,0), end_time=datetime.time(12,15), max_orders=20)
slot2 = TimeSlot(start_time=datetime.time(12,15), end_time=datetime.time(12,30), max_orders=20)
db.add_all([slot1, slot2])
db.commit()

print("Seed data added successfully!")