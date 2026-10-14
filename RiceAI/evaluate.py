from pathlib import Path

import torch
import torch.nn as nn
from torch.utils.data import DataLoader, Subset
from torchvision import datasets, transforms
from torchvision.models import efficientnet_b0
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    classification_report,
    confusion_matrix,
    ConfusionMatrixDisplay
)
import matplotlib.pyplot as plt

 

DATASET_DIR = Path("dataset")
MODEL_PATH = Path("models/rice_disease_efficientnet_b0.pth")

IMAGE_SIZE = 224
BATCH_SIZE = 16
SEED = 42

device = torch.device(
    "cuda" if torch.cuda.is_available() else "cpu"
)

print("=" * 60)
print("EVALUATE RICE DISEASE MODEL")
print("=" * 60)

print(f"Device: {device}")

if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")

 

eval_transform = transforms.Compose([
    transforms.Resize((IMAGE_SIZE, IMAGE_SIZE)),

    transforms.ToTensor(),

    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    )
])

 

dataset = datasets.ImageFolder(
    root=DATASET_DIR,
    transform=eval_transform
)

class_names = dataset.classes

labels = [sample[1] for sample in dataset.samples]

indices = list(range(len(dataset)))

 

train_indices, temp_indices = train_test_split(
    indices,
    test_size=0.30,
    random_state=SEED,
    stratify=labels
)

temp_labels = [labels[i] for i in temp_indices]

val_indices, test_indices = train_test_split(
    temp_indices,
    test_size=0.50,
    random_state=SEED,
    stratify=temp_labels
)

test_dataset = Subset(
    dataset,
    test_indices
)

test_loader = DataLoader(
    test_dataset,
    batch_size=BATCH_SIZE,
    shuffle=False,
    num_workers=0,
    pin_memory=torch.cuda.is_available()
)

print(f"\nTong dataset: {len(dataset)}")
print(f"Test images: {len(test_dataset)}")

 

print("\nDang load model...")

checkpoint = torch.load(
    MODEL_PATH,
    map_location=device,
    weights_only=False
)

class_names = checkpoint["class_names"]

num_classes = len(class_names)

model = efficientnet_b0(weights=None)

in_features = model.classifier[1].in_features

model.classifier[1] = nn.Linear(
    in_features,
    num_classes
)

model.load_state_dict(
    checkpoint["model_state_dict"]
)

model = model.to(device)

model.eval()

print("Da load model.")
print("Classes:")

for i, name in enumerate(class_names):
    print(f"  {i}: {name}")

 
all_predictions = []
all_targets = []

print("\nDang test...")

with torch.no_grad():

    for images, targets in test_loader:

        images = images.to(device)

        outputs = model(images)

        predictions = torch.argmax(
            outputs,
            dim=1
        )

        all_predictions.extend(
            predictions.cpu().numpy()
        )

        all_targets.extend(
            targets.numpy()
        )
 
cm = confusion_matrix(
    all_targets,
    all_predictions
)

print("\n" + "=" * 60)
print("CONFUSION MATRIX")
print("=" * 60)

print("\nRows = Actual")
print("Columns = Predicted\n")

print(cm)
 
print("\n" + "=" * 60)
print("CLASSIFICATION REPORT")
print("=" * 60)

print(
    classification_report(
        all_targets,
        all_predictions,
        target_names=class_names,
        digits=4
    )
)

 
correct = sum(
    p == t
    for p, t in zip(
        all_predictions,
        all_targets
    )
)

accuracy = correct / len(all_targets)

print("=" * 60)
print(
    f"TEST ACCURACY: {accuracy * 100:.2f}%"
)
print("=" * 60)

 

fig, ax = plt.subplots(
    figsize=(10, 8)
)

disp = ConfusionMatrixDisplay(
    confusion_matrix=cm,
    display_labels=class_names
)

disp.plot(
    ax=ax,
    xticks_rotation=45,
    cmap="Blues"
)

plt.title("Rice Disease - Confusion Matrix")

plt.tight_layout()

output_path = "confusion_matrix.png"

plt.savefig(
    output_path,
    dpi=200
)

plt.show()

print(
    f"\nDa luu confusion matrix: {output_path}"
)