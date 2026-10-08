# Confidence-Aware Adaptive Multimodal Routing Specification

## Theoretical Framework

The primary research contribution of OmniSense is **Confidence-Aware Adaptive Multimodal Routing**.

Rather than passing every user query and camera frame to a single large, computationally expensive Vision-Language Model (VLM), OmniSense employs a lightweight supervised Machine Learning classifier combined with a calibrated confidence router.

$$\text{Query } q \longrightarrow \text{ML Classifier } \mathcal{M}(q) \longrightarrow (\hat{y}, \hat{p})$$

Where $\hat{y} \in \{1, \dots, 16\}$ represents the predicted intent class, and $\hat{p} = P(Y = \hat{y} \mid q)$ represents the estimated intent probability.

---

## Routing Policy

$$\mathcal{R}(\hat{y}, \hat{p}) = 
\begin{cases} 
\text{DirectModuleDispatch}(\hat{y}) & \text{if } \hat{p} \ge 0.70 \quad (\text{HIGH}) \\
\text{DirectModuleDispatch}(\hat{y}) + \text{ValidationWarning} & \text{if } 0.45 \le \hat{p} < 0.70 \quad (\text{MEDIUM}) \\
\text{ActivePerception Clarification} & \text{if } \hat{p} < 0.45 \quad (\text{LOW})
\end{cases}$$

---

## Active Perception Clarification Workflow

When confidence is low ($\hat{p} < 0.45$), OmniSense avoids making unwarranted assumptions. It prompts the user via audio:

> *"I am not completely certain of your request. Would you like me to inspect objects in the room or read text from a document?"*

This active perception step reduces execution errors, improves user trust, and optimizes computational efficiency.
