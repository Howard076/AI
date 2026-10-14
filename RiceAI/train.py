 
from pathlib import Path
import random

import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from torchvision import datasets, transforms
from torchvision.models import efficientnet_b0, EfficientNet_B0_Weights
from tqdm import tqdm

DATASET_DIR = Path("data_split")
MODEL_DIR = Path("models")
MODEL_DIR.mkdir(exist_ok=True)
MODEL_PATH = MODEL_DIR / "rice_disease_efficientnet_b0.pth"

IMAGE_SIZE = 224
BATCH_SIZE = 16
EPOCHS = 15
LEARNING_RATE = 0.0001
SEED = 42

random.seed(SEED)
torch.manual_seed(SEED)

if torch.cuda.is_available():
    torch.cuda.manual_seed_all(SEED)

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

print("=" * 60)
print("RICE DISEASE CLASSIFICATION")
print("=" * 60)
print(f"Device: {device}")

if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")

print()

train_transform = transforms.Compose([
    transforms.Resize((IMAGE_SIZE, IMAGE_SIZE)),
    transforms.RandomHorizontalFlip(),
    transforms.RandomRotation(15),
    transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

eval_transform = transforms.Compose([
    transforms.Resize((IMAGE_SIZE, IMAGE_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

print("Dang doc dataset...")

train_dataset = datasets.ImageFolder(DATASET_DIR / "train", transform=train_transform)
val_dataset = datasets.ImageFolder(DATASET_DIR / "validation", transform=eval_transform)
test_dataset = datasets.ImageFolder(DATASET_DIR / "test", transform=eval_transform)

class_names = train_dataset.classes
num_classes = len(class_names)

if val_dataset.classes != class_names or test_dataset.classes != class_names:
    raise ValueError("Danh sach lop benh giua Train, Validation va Test khong khop.")

if num_classes < 2 or len(train_dataset) == 0 or len(val_dataset) == 0 or len(test_dataset) == 0:
    raise ValueError("Dataset khong hop le hoac thieu du lieu.")

print(f"So class: {num_classes}")
print("Classes:")

for i, class_name in enumerate(class_names):
    print(f"  {i}: {class_name}")

print(f"\nTong so anh: {len(train_dataset) + len(val_dataset) + len(test_dataset)}")
print(f"Train: {len(train_dataset)}")
print(f"Validation: {len(val_dataset)}")
print(f"Test: {len(test_dataset)}")

train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, shuffle=True, num_workers=0, pin_memory=torch.cuda.is_available())
val_loader = DataLoader(val_dataset, batch_size=BATCH_SIZE, shuffle=False, num_workers=0, pin_memory=torch.cuda.is_available())
test_loader = DataLoader(test_dataset, batch_size=BATCH_SIZE, shuffle=False, num_workers=0, pin_memory=torch.cuda.is_available())

print("\nDang tai EfficientNet-B0...")

model = efficientnet_b0(weights=EfficientNet_B0_Weights.DEFAULT)
in_features = model.classifier[1].in_features
model.classifier[1] = nn.Linear(in_features, num_classes)
model = model.to(device)

print("Da thay classifier.")
print(f"Output classes: {num_classes}")

criterion = nn.CrossEntropyLoss()
optimizer = torch.optim.AdamW(model.parameters(), lr=LEARNING_RATE, weight_decay=0.0001)

best_val_accuracy = -1.0

print("\nBat dau training...")
print("=" * 60)

for epoch in range(EPOCHS):
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0

    progress_bar = tqdm(train_loader, desc=f"Epoch {epoch + 1}/{EPOCHS}")

    for images, targets in progress_bar:
        images = images.to(device)
        targets = targets.to(device)

        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, targets)
        loss.backward()
        optimizer.step()

        running_loss += loss.item() * images.size(0)
        predicted = outputs.argmax(dim=1)
        total += targets.size(0)
        correct += (predicted == targets).sum().item()

        progress_bar.set_postfix(loss=f"{running_loss / total:.4f}", acc=f"{correct / total:.4f}")

    train_loss = running_loss / total
    train_accuracy = correct / total

    model.eval()
    val_loss = 0.0
    val_correct = 0
    val_total = 0

    with torch.no_grad():
        for images, targets in val_loader:
            images = images.to(device)
            targets = targets.to(device)

            outputs = model(images)
            loss = criterion(outputs, targets)

            val_loss += loss.item() * images.size(0)
            predicted = outputs.argmax(dim=1)
            val_total += targets.size(0)
            val_correct += (predicted == targets).sum().item()

    val_loss /= val_total
    val_accuracy = val_correct / val_total

    print(f"\nEpoch {epoch + 1}/{EPOCHS}")
    print(f"Train Loss: {train_loss:.4f} | Train Acc: {train_accuracy * 100:.2f}%")
    print(f"Val Loss: {val_loss:.4f} | Val Acc: {val_accuracy * 100:.2f}%")

    if val_accuracy > best_val_accuracy:
        best_val_accuracy = val_accuracy
        torch.save({
            "model_state_dict": model.state_dict(),
            "class_names": class_names,
            "image_size": IMAGE_SIZE,
            "model_name": "efficientnet_b0",
            "num_classes": num_classes
        }, MODEL_PATH)
        print(f"--> Da luu model tot nhat: {MODEL_PATH}")

print("\n" + "=" * 60)
print("TRAINING HOAN TAT")
print("=" * 60)
print(f"Best Validation Accuracy: {best_val_accuracy * 100:.2f}%")

print("\nDang load model tot nhat...")
checkpoint = torch.load(MODEL_PATH, map_location=device, weights_only=True)
model.load_state_dict(checkpoint["model_state_dict"])
model.eval()

print("Dang test model...")

test_correct = 0
test_total = 0

with torch.no_grad():
    for images, targets in test_loader:
        images = images.to(device)
        targets = targets.to(device)

        outputs = model(images)
        predicted = outputs.argmax(dim=1)

        test_total += targets.size(0)
        test_correct += (predicted == targets).sum().item()

test_accuracy = test_correct / test_total

print(f"\nTest Accuracy: {test_accuracy * 100:.2f}%")
print(f"Model saved at: {MODEL_PATH}")
print("\nHoan thanh!")
 