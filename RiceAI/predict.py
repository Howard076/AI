from pathlib import Path
import sys

import torch
import torch.nn as nn
from PIL import Image
from torchvision import transforms
from torchvision.models import efficientnet_b0
#.\venv\Scripts\Activate.ps1
#python predict.py test_images/rice.jpg
MODEL_PATH = Path("models/rice_disease_efficientnet_b0.pth")

IMAGE_SIZE = 224

device = torch.device(
    "cuda" if torch.cuda.is_available() else "cpu"
)

print("=" * 60)
print("RICE DISEASE PREDICTION")
print("=" * 60)

print(f"Device: {device}")

if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")



if len(sys.argv) < 2:
    print("\n❌ Chưa nhập đường dẫn ảnh.")
    print("Ví dụ:")
    print("python predict.py test_images/anh.jpg")
    sys.exit()


image_path = Path(sys.argv[1])

if not image_path.exists():
    print(f"\n❌ Không tìm thấy ảnh: {image_path}")
    sys.exit()

 

print("\nĐang load model...")

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

print("Đã load model.")
 
transform = transforms.Compose([
    transforms.Resize((IMAGE_SIZE, IMAGE_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    )
])

 

image = Image.open(image_path).convert("RGB")

input_tensor = transform(image)

input_tensor = input_tensor.unsqueeze(0)

input_tensor = input_tensor.to(device)

 

with torch.no_grad():

    output = model(input_tensor)

    probabilities = torch.softmax(
        output,
        dim=1
    )[0]

    top_probabilities, top_indices = torch.topk(
        probabilities,
        k=min(3, num_classes)
    )

 

print("\n" + "=" * 60)
print("KẾT QUẢ")
print("=" * 60)

print(f"\nẢnh: {image_path}")

print("\nTop 3 dự đoán:")

for rank, (prob, index) in enumerate(
    zip(top_probabilities, top_indices),
    start=1
):

    class_name = class_names[index.item()]
    confidence = prob.item() * 100

    print(
        f"{rank}. {class_name}: "
        f"{confidence:.2f}%"
    )

print("\n" + "=" * 60)

print(
    f"DỰ ĐOÁN: "
    f"{class_names[top_indices[0].item()]}"
)

print(
    f"CONFIDENCE: "
    f"{top_probabilities[0].item() * 100:.2f}%"
)

print("=" * 60)