# databricks-edge
train on Azure Databricks, inference on IoT Edge

# train on cloud, inference on edge

1. create aml workspace - link /w ACR and Blob
either Aportal, or CLI:

```
az ml workspace create -n <workspace-name> -g <resource-group-name> --container-registry <acr-name>
```

2. connect databricks /w aml
did this via portal 
 
3. training in aml / databricks
see training.ipynb

4. create run.py
see inference.ipynb / terminal 

```
vi inference.py
``` 

```
import pickle

def inference(inp):
    loaded_model = pickle.load(open("model.pkl", 'rb'))
    print(loaded_model.predict(context=None, model_input=[inp]))
    
if __name__ == '__main__':
    inference([input()])


5. create container manifest

```
vi Dockerfile
```

```
FROM python:3.9-slim-buster

# Set working directory
WORKDIR /app

# Copy MLflow artifact and inference script
COPY artifact/model.pkl /app
COPY artifact/requirements.txt /app
COPY inference.py /app

# Install dependencies
RUN pip install -r requirements.txt

# Expose port for inference
EXPOSE 8080

# Start server
CMD ["python", "inference.py"]
```

6. get artifacts stored in dbfs to workspace local storage 
manual, temrinal via ```cp```

7. do docker stuff to ACR
terminal / %% in notebook, 

```
docker build -t <image_name> .
```

```
az acr login --name <registry_name> --subscription <subscription_id>
```

```
docker tag <image_name> <registry_name>.azurecr.io/<image_name>:<tag>
```

```
docker push <registry_name>.azurecr.io/<image_name>:<tag>
```

8. create deploy manifest / local terminal  azure portal etc.  

```
vi <dpl-manifest.json>
```

either get it form Portal via IoT Hub, or - actually is the best. otherwise, too much manual adjustments. 

```
{
    "modulesContent": {
        "$edgeAgent": {
            "properties.desired": {
                "schemaVersion": "1.1",
                "runtime": {
                    "type": "docker",
                    "settings": {
                        "registryCredentials": {
                            "docker": {
                                "address": "<registry-name>.azurecr.io",
                                "password": "<some-azure-generated-pw>",
                                "username": "<registry-name>"
                            }
                        }
                    }
                },
                "systemModules": {
                    "edgeAgent": {
                        "settings": {
                            "image": "mcr.microsoft.com/azureiotedge-agent:1.4"
                        },
                        "type": "docker"
                    },
                    "edgeHub": {
                        "restartPolicy": "always",
                        "settings": {
                            "image": "mcr.microsoft.com/azureiotedge-hub:1.4",
                            "createOptions": "{\"HostConfig\":{\"PortBindings\":{\"443/tcp\":[{\"HostPort\":\"443\"}],\"5671/tcp\":[{\"HostPort\":\"5671\"}],\"8883/tcp\":[{\"HostPort\":\"8883\"}]}}}"
                        },
                        "status": "running",
                        "type": "docker"
                    }
                },
                "modules": {
                    "edge-inference": {
                        "version": "1.0",
                        "type": "docker",
                        "status": "running",
                        "restartPolicy": "always",
                        "settings": {
                            "image": "<regsitry-name>.azurecr.io/<container-name>:latest",
                            "createOptions": ""
                        }
                    }
                }
            }
        },
        "$edgeHub": {
            "properties.desired": {
                "schemaVersion": "1.1",
                "storeAndForwardConfiguration": {
                    "timeToLiveSecs": 7200
                },
                "routes": {}
            }
        }
    }
}
```

9. deploy container to edge / from local terminal again via azure CLI, or Portal
important: edge device must be installed edge runtime (see A,B,C...)

```
az iot edge set-modules --device-id <device-name> --hub-name <hub-name> --content <dpl-manifest.json>
```

... abfahrt 

# if edge has no edge runtime 
see: https://learn.microsoft.com/de-de/azure/iot-edge/how-to-provision-single-device-linux-symmetric?view=iotedge-1.4&tabs=azure-portal%2Cubuntu 

