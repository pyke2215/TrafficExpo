from huggingface_hub import snapshot_download

snapshot_download(
    repo_id="OpenHay/zalo-ai-2025-training-data-v2",
    repo_type="dataset",
    allow_patterns=["frames/*.jpg"],
    local_dir=r"E:\Phat\TrafficExpo\perception\datasets\raw\roadbuddy",
)
print("DONE")
