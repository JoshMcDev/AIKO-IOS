#!/usr/bin/env python3

import json
import os
from datetime import datetime

# Task status updates based on our audit
TASK_UPDATES = {
    "1": {
        "status": "done",
        "notes": "Document parser fully implemented with PDF/Word/Image support",
        "subtasks": {
            "1.1": "done",
            "1.2": "done", 
            "1.3": "done",
            "1.4": "done",
            "1.5": "done"
        }
    },
    "8": {
        "status": "done",
        "notes": "Offline caching system fully implemented",
        "subtasks": {
            "1": "done",  # Note: Task 8 subtasks use numeric IDs
            "2": "done",
            "3": "done",
            "4": "done"
        }
    },
    "3": {
        "status": "in-progress",
        "notes": "Pattern detection partially implemented",
        "subtasks": {
            "3.1": "done",
            "3.2": "pending",
            "3.3": "pending",
            "3.4": "pending",
            "3.5": "pending"
        }
    },
    "4": {
        "status": "in-progress",
        "notes": "FAR compliance partially implemented",
        "subtasks": {
            "4.1": "pending",
            "4.2": "done",
            "4.3": "pending",
            "4.4": "pending",
            "4.5": "pending"
        }
    },
    "9": {
        "status": "in-progress",
        "notes": "Basic compliance checking implemented"
    }
}

def update_task_status(task, updates):
    """Update a task's status based on the updates dict"""
    task_id = task.get("id")
    if task_id in updates:
        update = updates[task_id]
        task["status"] = update["status"]
        
        # Update subtasks if they exist
        if "subtasks" in update and "subtasks" in task:
            for subtask in task["subtasks"]:
                subtask_id = subtask.get("id")
                if subtask_id in update["subtasks"]:
                    subtask["status"] = update["subtasks"][subtask_id]
                    print(f"  Updated subtask {subtask_id} to {subtask['status']}")
        
        print(f"Updated task {task_id} to {task['status']}")

def main():
    tasks_file = "/Users/J/aiko/.taskmaster/tasks/tasks.json"
    
    # Read the current tasks
    with open(tasks_file, 'r') as f:
        data = json.load(f)
    
    # Create backup
    backup_file = f"{tasks_file}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    with open(backup_file, 'w') as f:
        json.dump(data, f, indent=2)
    print(f"Created backup: {backup_file}")
    
    # Update task statuses
    print("\nUpdating task statuses...")
    for task in data["master"]["tasks"]:
        update_task_status(task, TASK_UPDATES)
    
    # Write updated tasks back
    with open(tasks_file, 'w') as f:
        json.dump(data, f, indent=2)
    
    print(f"\nTask statuses updated successfully!")
    print(f"Updated file: {tasks_file}")
    
    # Summary
    print("\nSummary of changes:")
    for task_id, update in TASK_UPDATES.items():
        print(f"  Task {task_id}: {update['status']} - {update['notes']}")

if __name__ == "__main__":
    main()