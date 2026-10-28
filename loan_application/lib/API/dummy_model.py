import pickle
from sklearn.linear_model import LogisticRegression
import numpy as np

# Flask အလုပ်လုပ်ဖို့အတွက် ယာယီ Dummy Model တစ်ခုဆောက်ခြင်း
dummy_model = LogisticRegression()
X = np.array([[5], [10], [15]])
y = np.array([0, 1, 0])
dummy_model.fit(X, y)

# ဖိုင်အသစ်အဖြစ်သိမ်းဆည်းခြင်း
with open("intent_classifier.pkl", "wb") as f:
    pickle.dump(dummy_model, f)

print("ယာယီစမ်းသပ်ရန် intent_classifier.pkl ဖိုင်ကို အောင်မြင်စွာဆောက်လုပ်ပြီးပါပြီ။")