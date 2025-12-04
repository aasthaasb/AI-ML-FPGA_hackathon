# AI-ML-FPGA_hackathon
AI-Driven Traffic Congestion Prediction &amp; FPGA Based Signal Controller
# AI-Driven Traffic Congestion Prediction & FPGA-Based Adaptive Signal Controller  
**Author:** Aastha Bhore, IIT Jodhpur  
**Hackathon Project Repository**

---

## Overview  
This project integrates **Machine Learning** and **FPGA hardware** to create an **adaptive traffic signal controller** that changes green-light durations based on predicted congestion.

The ML model predicts congestion levels (0–3), which the FPGA uses to modify timing in real-time while enforcing yellow and all-red safety intervals and a deterministic fail-safe mode.

---

## Machine Learning Model  
- Implemented using `Traffic_Predictor.ipynb`  
- Trained Random Forest Regressor on Kaggle Traffic Prediction Dataset  
- Predictions quantized into **4 levels**  
- Exported to FPGA as a memory file: `levels.mem`  
- Model metrics include MSE, RMSE, MAE, R²

---

##FPGA Architecture  
Written in pure Verilog RTL.

Components:
- 6-state traffic-light FSM  
- LUT-based adaptive green timing  
- Yellow & All-Red safety intervals  
- Automatic fail-safe override  
- Memory-driven ML input via `$readmemh("levels.mem")`

---

## Simulation  
Vivado simulation demonstrates:
- Correct congestion-level input  
- Adaptive green duration  
- FSM transitions  
- Safety intervals  
- Fail-safe behavior  

Waveform available in repo as `waveform.png`.

---

## How It Works  

1. ML model predicts congestion  
2. Predictions → `levels.mem`  
3. Verilog testbench loads memory  
4. FSM chooses phase timing via LUT  
5. Output controls NS/EW traffic lights  

---

## Conclusion  
This hybrid ML + FPGA solution offers:
- Real-time adaptivity  
- Deterministic timing guarantees  
- Safety-critical behavior  
- Deployment-ready architecture  




