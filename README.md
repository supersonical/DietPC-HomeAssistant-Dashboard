# DietPC-HomeAssistant-Dashboard
Optimized DietPI OS for HomeAssistant dashboard running on a old meeting room booking screen. 
## Quick Start

Option A: Run directly via curl (no git required):

```
curl -fsSL https://raw.githubusercontent.com/supersonical/DietPC-HomeAssistant-Dashboard/main/setup.sh | sudo bash
```

Option B: Download tarball and run:

```
curl -L https://github.com/supersonical/DietPC-HomeAssistant-Dashboard/archive/refs/heads/main.tar.gz -o repo.tar.gz
mkdir repo && tar -xzf repo.tar.gz -C repo --strip-components=1
cd repo && sudo bash setup.sh
```

Option C: Clone the repo:

```
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/supersonical/DietPC-HomeAssistant-Dashboard.git
cd DietPC-HomeAssistant-Dashboard
sudo bash setup.sh
```

Follow prompts.
