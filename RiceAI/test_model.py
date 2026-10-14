import torch
from torchvision.models import efficientnet_b0, EfficientNet_B0_Weights

print("PyTorch:", torch.__version__)
print("CUDA:", torch.cuda.is_available())

if torch.cuda.is_available():
    print("GPU:", torch.cuda.get_device_name(0))

print("\nDang tai EfficientNet-B0...")

weights = EfficientNet_B0_Weights.DEFAULT

model = efficientnet_b0(weights=weights)

print("\nEfficientNet-B0 da tai thanh cong!")
print("So parameters:", sum(p.numel() for p in model.parameters()))