# Comparing Pre-op and Post-op ADL Scores of Hip Fracture Patients

The data comes from a longitudinal observational study, the aim of which is to study the post-operative evolution of the physical ability of elderly hipfracture patients and their pre-operative cognitive status, and to study the effects of housing situation and age on these evolutions. The physical ability is measured using the ADL (Activities of Daily Living) score, with values between 6 and 24, where low values correspond to little physical dependency of the patient, while high scores correspond to high physical dependency. The cognitive status is measured through the so-called ‘neuro-status’ which is a binary indicator for being neuro-psychiatric or not.

The variables are:
- id: patient identification number
- age: age of the patient at entry
- neuro: neuro-psychiatric status of the patient (1: neuro-psychiatric, 0: not neuropsychiatric)
- adl: ADL score
- time: day after operation at which the ADL score has been measured (1, 5 or 12)
- housing situation: the housing situation prior to the hip fracture (1: alone, 2: with family or partner, 3: nursing home)

Procedures used:
- proc mixed
- proc glimmix

## Analysis Steps
- Data is described. Mean, variance and correlation structures are explored. In general, patients without neuro-psychiatric status, on average, achieved a decrease in adl scores over time. Another thing to note is that there seems to be small within-subject variability, compared to the between subject variability. This is an indication of high correlation in the data, which is common in longitudinal studies.
- Then, a linear mixed model is fitted to the data - with random intercept and random slope for each patient. The model indicates that the neuropsychiatric patients gain physical independence at a slower rate, if at all. A possible explanation for the difference is the fact that after hip surgery, considerable post-op care must be taken and special rehabilitation exercises must be performed in order to have a satisfactory recovery. Looking at the variance and correlation structure, the model underestimates the variance, most probably due to dropouts. In conclusion, neuropsychiatric patients have higher adl scores in the beginning, and their recovery process is slower.
- Also, housing and age factors are added to fit a new model. So, people in nursing homes are worse off in adl score (higher physical dependence) than others while there is no difference for the rest. Also, baseline differences between neuropsychiatric patients become non-significant after controlled by housing effect.
- As an alternative model, adl score is dichotomized (<17=low and ≥17=high) according to the balance of the dataset. Then, a logistic mixed model is fitted to the data. Random slopes are dropped and random intercepts are retained in this new model. First thing to notice is that the non-neuropsychiatric patients start with lower probability thanthe neuropsychiatric patients. Also, their decrease in probability seems steeper than the decrease of non-neuropsychiatric patients. europsychiatric patients may not even regain their physical independence, while non-neuropsychiatric patients are more likely to regain their physical independence and much quicker. Hence, the results of the first models are validated via probabilistic approaches.
