import os
import shutil
from pathlib import Path
import re

def get_next_backup_number(source_path):
    """Get the next available backup number by checking existing backup folders."""
    source_name = Path(source_path).name
    parent_dir = Path(source_path).parent
    
    # Look for existing backup folders with pattern: foldername_X
    backup_pattern = f"{source_name}_"
    existing_backups = [d for d in os.listdir(parent_dir) 
                       if os.path.isdir(os.path.join(parent_dir, d)) 
                       and d.startswith(backup_pattern)]
    
    if not existing_backups:
        return 1
    
    # Extract numbers from existing backup folders
    numbers = []
    for backup in existing_backups:
        match = re.search(rf"{backup_pattern}(\d+)$", backup)
        if match:
            numbers.append(int(match.group(1)))
    
    return max(numbers, default=0) + 1

def create_backup(source_path):
    """Create a backup of the specified folder with an incremented number."""
    if not os.path.exists(source_path):
        print(f"Error: Source path '{source_path}' does not exist!")
        return False
    
    if not os.path.isdir(source_path):
        print(f"Error: '{source_path}' is not a directory!")
        return False
    
    next_number = get_next_backup_number(source_path)
    source_name = Path(source_path).name
    backup_name = f"{source_name}_{next_number}"
    backup_path = os.path.join(Path(source_path).parent, backup_name)
    
    try:
        shutil.copytree(source_path, backup_path)
        print(f"Successfully created backup: {backup_name}")
        return True
    except Exception as e:
        print(f"Error creating backup: {str(e)}")
        return False

def create_backup_current():
    """Create a backup of the current folder in its parent directory."""
    # Get the current directory
    current_dir = os.getcwd()
    
    # Get the parent directory
    parent_dir = str(Path(current_dir).parent)
    
    # Get the name of the current folder
    folder_name = os.path.basename(current_dir)
    
    # Get the next backup number
    next_number = get_next_backup_number(current_dir)
    
    # Create the backup folder name
    backup_name = f"{folder_name}_{next_number}"
    backup_path = os.path.join(parent_dir, backup_name)
    
    try:
        shutil.copytree(current_dir, backup_path)
        print(f"Successfully created backup: {backup_name}")
        return True
    except Exception as e:
        print(f"Error creating backup: {str(e)}")
        return False

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) == 1:
        create_backup_current()
    elif len(sys.argv) == 2:
        source_path = sys.argv[1]
        create_backup(source_path)
    else:
        print("Usage: python fb.py [folder_path]")
        sys.exit(1)
