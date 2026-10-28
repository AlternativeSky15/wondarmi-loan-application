from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import pandas as pd
import os

# 1. 'name' ကို Flask ရဲ့ သတ်မှတ်ချက်အတိုင်း 'name' ဟု အမှန်ပြင်ဆင်
app = Flask(__name__)
CORS(app)  # Cross-Origin Resource Sharing ကို အားလုံးအတွက် ခွင့်ပြုရန်

# 2. 'file' ကို လက်ရှိဖိုင်လမ်းကြောင်းသိအောင် 'file' ဟု အမှန်ပြင်ဆင်
MODEL_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "loan_eligibility_model.pkl")
model = joblib.load(MODEL_PATH) if os.path.exists(MODEL_PATH) else None

# အသုံးပြုသူတစ်ဦးချင်းစီရဲ့ အမေးအဖြေ State ကို မှတ်ထားရန် ယာယီ Memory
user_sessions = {}

# လမ်းကြောင်းလွဲရင်တောင် မိအောင် '/' ရော '/ask' ရော နှစ်မျိုးလုံး ဖမ်းပေးထားပါတယ်
@app.route('/', methods=['GET', 'POST'])
@app.route('/ask', methods=['GET', 'POST'])
def predict_loan():
    # GET Request ဖြင့် စမ်းသပ်ပါက ဆာဗာ အလုပ်လုပ်ကြောင်း အကြောင်းပြန်ရန်
    if request.method == 'GET':
        return jsonify({
            'status': 'success', 
            'loan_eligibility': 'Flask Server is running and ready for POST requests!'
        }), 200
    
    # POST Request အတွက် ဒေတာဖတ်ခြင်း
    data = request.get_json()
    if not data:
        return jsonify({'status': 'error', 'loan_eligibility': 'ဆာဗာသို့ ဒေတာ လုံးဝ ဝင်မလာပါ။ Format ကို စစ်ဆေးပါ။'}), 400
        
    # Flutter ဘက်က ရိုက်လိုက်တဲ့ တကယ့်စာသားကို ဖတ်ယူခြင်း
    user_message = data.get('user_message', '').strip()
    
    # Single user အနေဖြင့် 'default_user' ဟု သတ်မှတ်ခြင်း
    user_id = 'default_user' 
    
    if user_id not in user_sessions:
        user_sessions[user_id] = {'step': 1, 'data': {}}

    session = user_sessions[user_id]

    # စကားပြောခြင်း အဆင့်ဆင့် Logic
    if session['step'] == 1:
        session['step'] = 2
        return jsonify({
            'status': 'success', 
            'loan_eligibility': "မင်္ဂလာပါခင်ဗျာ 🙏 ချေးငွေရနိုင်ခြေကို စစ်ဆေးပေးပါ့မယ်။ သင့်ရဲ့ တစ်နှစ်ဝင်ငွေ (Income Annum) ကို ဂဏန်းသီးသန့် ရိုက်ထည့်ပေးပါဗျာ။"
        })

    elif session['step'] == 2:
        try:
            session['data']['income_annum'] = float(user_message)
            session['step'] = 3
            return jsonify({
                'status': 'success', 
                'loan_eligibility': "ဟုတ်ကဲ့ပါခင်ဗျာ။ လျှောက်ထားလိုတဲ့ ချေးငွေပမာဏ (Loan Amount) ကိုလည်း ဂဏန်းသီးသန့်လေး ရိုက်ပေးပါဦး။"
            })
        except:
            return jsonify({
                'status': 'success', 
                'loan_eligibility': "ကျေးဇူးပြု၍ ဝင်ငွေကို ဂဏန်းသီးသန့် (ဥပမာ - 500000) ပဲ ရိုက်ထည့်ပေးပါဗျာ။"
            })

    elif session['step'] == 3:
        try:
            session['data']['loan_amount'] = float(user_message)
            session['step'] = 4
            return jsonify({
                'status': 'success', 
                'loan_eligibility': "နောက်ဆုံးအနေနဲ့ သင့်ရဲ့ CIBIL Score (Credit Score) ကို ရိုက်ထည့်ပေးပါဗျာ။"
            })
        except:
            return jsonify({
                'status': 'success', 
                'loan_eligibility': "ကျေးဇူးပြု၍ ချေးငွေပမာဏကို ဂဏန်းသီးသန့်ပဲ ရိုက်ထည့်ပေးပါဗျာ။"
            })

    elif session['step'] == 4:
        try:
            session['data']['cibil_score'] = float(user_message)
            
            # မော်ဒယ်အတွက် လိုအပ်သော ကျန် feature များကို ပုံသေဖြည့်ခြင်း
            feature_names = [
                'no_of_dependents', 'education', 'self_employed', 'income_annum', 
                'loan_amount', 'loan_term', 'cibil_score', 'residential_assets_value', 
                'commercial_assets_value', 'luxury_assets_value', 'bank_asset_value'
            ]
            
            input_dict = {}
            for col in feature_names:
                if col in session['data']:
                    input_dict[col] = [session['data'][col]]
                elif col == 'loan_term':
                    input_dict[col] = [12.0]  # ပုံသေ ၁၂ လ ဟု ထည့်ခြင်း
                else:
                    input_dict[col] = [0.0]
                    # Model ဖြင့် အဖြေတွက်ခြင်း
            if model is not None:
                X_inside = pd.DataFrame(input_dict)
                prediction = model.predict(X_inside.values)
                result = "ချေးငွေ လျှောက်ထားနိုင်ပါသည် (Eligible) 🎉" if prediction[0] == 1 else "ချေးငွေ လျှောက်ထားရန် သတ်မှတ်ချက် မပြည့်မီပါ (Not Eligible) ❌"
            else:
                result = "ဆာဗာပေါ်တွင် Model File (.pkl) ကို ရှာမတွေ့ပါ။ ❌"
            
            # Session memory ကို ပြန်ဖျက်ပြီး အစက ပြန်စခိုင်းခြင်း
            del user_sessions[user_id]
            return jsonify({
                'status': 'success', 
                'loan_eligibility': f"အချက်အလက်များ အရ သင့်အတွက် ရလဒ်မှာ- {result}\n\nအသစ်ပြန်စစ်ချင်ရင် 'hi' လို့ ထပ်ရိုက်ပေးပါ။"
            })
            
        except Exception as e:
            if user_id in user_sessions:
                del user_sessions[user_id]
            return jsonify({
                'status': 'success', 
                'loan_eligibility': f"အမှားတစ်ခု ဖြစ်သွားလို့ စစ်ဆေးမှု ပျက်ပြယ်သွားပါပြီ။ Error: {str(e)}။ 'hi' ဟု ရိုက်ပြီး ပြန်စပေးပါ။"
            })

# 3. Running လုပ်မည့် Main Block ကို 'name' နှင့် 'main' ဟု အမှန်ပြင်ဆင်
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)