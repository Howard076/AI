from pathlib import Path
from io import BytesIO

import torch
import torch.nn as nn

from PIL import Image
from torchvision import transforms
from torchvision.models import efficientnet_b0

from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware

#uvicorn backend.main:app --host 0.0.0.0 --port 8000

BASE_DIR = Path(__file__).resolve().parent.parent

MODEL_PATH = BASE_DIR / "models" / "rice_disease_efficientnet_b0.pth"

IMAGE_SIZE = 224

device = torch.device(
    "cuda" if torch.cuda.is_available() else "cpu"
)


# ============================================================
# FASTAPI
# ============================================================

app = FastAPI(
    title="Rice Disease AI API",
    version="1.0.0"
)


# Cho phép Flutter gọi API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# LOAD MODEL
# ============================================================

print("=" * 60)
print("RICE DISEASE AI API")
print("=" * 60)

print(f"Device: {device}")

if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")

print("\nĐang load model...")

checkpoint = torch.load(
    MODEL_PATH,
    map_location=device,
    weights_only=False
)

class_names = checkpoint["class_names"]

num_classes = len(class_names)

print(f"Classes: {class_names}")


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
print("=" * 60)


# ============================================================
# IMAGE TRANSFORM
# ============================================================

transform = transforms.Compose([
    transforms.Resize((IMAGE_SIZE, IMAGE_SIZE)),

    transforms.ToTensor(),

    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    )
])


# ============================================================
# HOME
# ============================================================

@app.get("/")
def root():

    return {
        "message": "Rice Disease AI API is running",
        "device": str(device),
        "classes": class_names
    }


# ============================================================
# PREDICT
# ============================================================

@app.post("/predict")
async def predict(
    file: UploadFile = File(...)
):

    # --------------------------------------------------------
    # READ IMAGE
    # --------------------------------------------------------

    image_bytes = await file.read()

    try:

        image = Image.open(
            BytesIO(image_bytes)
        ).convert("RGB")

    except Exception:

        return {
            "success": False,
            "message": "File không phải ảnh hợp lệ."
        }


    # --------------------------------------------------------
    # PREPROCESS
    # --------------------------------------------------------

    input_tensor = transform(image)

    input_tensor = input_tensor.unsqueeze(0)

    input_tensor = input_tensor.to(device)


    # --------------------------------------------------------
    # MODEL PREDICTION
    # --------------------------------------------------------

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


    # --------------------------------------------------------
    # TOP 3
    # --------------------------------------------------------

    top_predictions = []

    for prob, index in zip(
        top_probabilities,
        top_indices
    ):

        top_predictions.append({

            "class_name": class_names[index.item()],

            "confidence": round(
                prob.item() * 100,
                2
            )

        })


    # --------------------------------------------------------
    # BEST RESULT
    # --------------------------------------------------------

    best_index = top_indices[0].item()

    best_probability = top_probabilities[0].item()


    # --------------------------------------------------------
    # RESPONSE
    # --------------------------------------------------------

    return {

        "success": True,

        "prediction": class_names[best_index],

        "confidence": round(
            best_probability * 100,
            2
        ),

        "top_predictions": top_predictions

    }