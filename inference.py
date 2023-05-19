import pickle
import sys

def inference(*args):

    inp = [float(i) for i in args]
    print(f'input values are: {inp}')
    loaded_model = pickle.load(open("python_model.pkl", 'rb'))
    inf= loaded_model.predict(context=None, model_input=[inp])
    print(f'inferenced value is: {inf}')

if __name__ == '__main__':
    inference(sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4])
