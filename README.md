# Introduction 
train on Azure Databricks, inference on IoT Edge.
A full infra & app documentation allowing to train ML models in Azure Databricks, based on Data from Aspen via Data Factory, producitve inference on edge. 

# 1. Getting Started
a.	Installation process
variables:
```
datafactory=$TODO
```
```
databricks=$DataBrickManufacturingHH
```
```
devops=$Digital Factory Hamburg
```
```
devops=$Digital Factory Hamburg
```
```
pipelines=$Digital Factory Hamburg - $PIN
```
```
registry=$ContainerRegManufacturingHH
```
```
repository=$digitalfactoryhamburg - $PIN
```
```
repository=$HHManufacturingIoTHub
```
```
repository=$DEHAMSIOTEDGE
```
```
module=$PIN
```
b.	Software dependencies
```
mlflow
```
```
cloudpickle==2.2.1
```
```
scikit-learn==1.0.2
```
TODO databricks dependencies 

c. latest releases 
TODO databricks push automation
TODO devops pipeline build on target automation 
TODO OPC module

# Build and Test
TODO: Describe and show how to build your code and run the tests. 

# Contribute
TODO: Explain how other users and developers can contribute to make your code better. 

If you want to learn more about creating good readme files then refer the following [guidelines](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-a-readme?view=azure-devops). You can also seek inspiration from the below readme files:
- [ASP.NET Core](https://github.com/aspnet/Home)
- [Visual Studio Code](https://github.com/Microsoft/vscode)
- [Chakra Core](https://github.com/Microsoft/ChakraCore)



# databricks-edge
train on Azure Databricks, inference on IoT Edge

# train on cloud, inference on edge

1. create aml workspace - link /w ACR and Blob
either via Portal, or CLI:

```
az ml workspace create -n <workspace-name> -g <resource-group-name> --container-registry <acr-name>
```

2. connect databricks /w aml
did this via portal 
 
3. dummy training Experiment I did: see ```training.ipynb``` in aml / databricks
this pipeline 1. preprocesses data, 2. creates & runs experiemnt / trains model, and 3. saves/ registers model  

4. for edge-inference, we create a run.py file as entrypoint in our container on our edge devices.
can be done either via workbook:

```
inference.ipynb
```

or terminal and vim:

```
vi inference.py
``` 

5. create container manifest 
done via vim

```
vi Dockerfile
```

```
FROM python:3.9-slim-buster

LABEL maintainer="nikolai.arras@accenture.com"

# Set working directory
WORKDIR /app

# Copy MLflow artifact and inference script
COPY artifact/model.pkl /app
COPY artifact/requirements.txt /app
COPY inference.py /app

# Install dependencies
RUN pip install -r requirements.txt

# Expose port for inference
EXPOSE 80

# Start server
ENTRYPOINT ["python", "inference.py"]
```

6. get artifacts stored in dbfs to workspace local storage 
manual, temrinal via ```cp``` 
we need the following files: 
1. dockerfile (already in workspace local storage), 
2. run.py (already in workspace local storage), 
3. model.pkl (can be derived via temrinal from dbfs, but is also already a variable in workspace as ```wrappedModel``` variable [if variable is used, just make sure to convert it once as pkl hard coded to local workspace storage],
4. requirements.txt (can be derived via temrinal from dbfs, but is also already a variable in workspace [if variable is used, just make sure to convert it once as txt hard coded to local workspace storage]
5. conda_env (can be derived via temrinal from dbfs, but is also already a variable in workspace as ```conda_env``` variable [if variable is used, just make sure to convert it once as yaml hard coded to local workspace storage],


7. do docker stuff to ACR
either via (a) terminal or via (b) in notebook and azure ML core enviornment DockerSection class 

1a
```
docker build -t <image_name> .
```

2a.
```
az acr login --name <registry_name> --subscription <subscription_id>
```

3a.
```
docker tag <image_name> <registry_name>.azurecr.io/<image_name>:<tag>
```

4a.
```
docker push <registry_name>.azurecr.io/<image_name>:<tag>
```

b. see: https://learn.microsoft.com/de-de/python/api/azureml-core/azureml.core.environment.dockersection?view=azure-ml-py

8. create deploy manifest / local terminal  azure portal etc.  
we create deployment manifest once.

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

ALTERNATIVE: 
if you dont want to build the container image via command line, one can use the AML & ADB enviornment classes: 
see here: https://learn.microsoft.com/de-de/python/api/azureml-core/azureml.core.environment.environment?view=azure-ml-py
