<img width="442" alt="image" src="https://github.com/dostojewskyi/databricks-edge/assets/58233550/103607f8-5f6a-4175-b657-219897b5404c"># 1. Introduction 
train on Azure Databricks, inference on IoT Edge.
A full infra & app documentation allowing to train ML models in Azure Databricks, based on Data from Aspen via Data Factory, producitve inference on edge. 

![Infrastructure diagram.]([https://content.codecademy.com/courses/learn-cpp/community-challenge/highfive.gif](https://github.com/dostojewskyi/databricks-edge/blob/main/databricks_to_edge.png))


# 2. Getting Started
a.	Installation process
variables:
```
$datafactory=TODO
```
```
$databricks=DataBrickManufacturingHH
```
```
$notebook=Visco_Rise_Cook_Time
```
```
$devops=Digital Factory Hamburg
```
```
$model=PIN
```
```
$pipelines=Digital Factory Hamburg - $model
```
```
$containerregistry=ContainerRegManufacturingHH
```
```
$containerrepository=digitalfactoryhamburg-$model
```
```
$iothub=HHManufacturingIoTHub
```
```
$device=DEHAMSIOTEDGE
```
```
$module=PIN
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

TODO: create configure databricks 
TODO: create configure data factory

After follow along the “getting started” section, the following infrastructure is configured as follows:
- Data Factory instance is configered as descripted 
- Databricks instance is configered as descripted 
- Databricks notebooks are configered as descripted 
- DevOps instance and repository are configered as descripted 
- Azure Container registry are configured as descripted 
- Azure IoT Hub and Edge devices are configured as descripted

set up ACR
```
az acr create --name $containerregistry --resource-group ManufacturingDataEU --sku Basic --admin-enabled true --tags [Creator[=$creator] environment[= DEV] Project[= CloudEdge]] --location europe-norh
```

set up IoT Húb
```
az iot hub create --name HHManufacturingIoTHub --resource-group ManufacturingDataEU --location west-europe --sku s1
```

create Edge Device
```
az iot hub device-identity create --device-id DEHAMSIOTEDGE --am shared_private_key --edge-enabled = true 
```

spin up VM as edge 
```
az vm create --name --resource-group datamanufacturingeu --authentication-type all --image Ubuntu2204 
```

on the edge VM! (ubuntu)
- install IoTedge
```
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb sudo dpkg -i packages-microsoft-prod.deb rm packages-microsoft-prod.deb
```
- Install container engine
```
sudo apt-get update; \ sudo apt-get install moby-engine
```
- Install IoTedge runtime
```
sudo apt-get update; \ sudo apt-get install aziot-edge
```
- Provising device /w Cloud identity
```
sudo iotedge config mp --connection-string 'PASTE_DEVICE_CONNECTION_STRING_HERE’
```

# 3. Train and Build

1. 
Data factory ```$TODO``` gets data from data datbase ASPEN. preprocessing via ```$TODO```.

2. 
Model training and hyperparamether tuning via databricks ```$databricks``` notebook ```$notebook``` in Repo ```devops```, with support of MLflow.

3.
Run Model registration, loging and storage of artifacts with MLflow.

4.
Artifacts of Best run, inference method of Registered Model is stored on lovel ```/$model```

5.
TODO: put, delete, post on level ```/$model```push updates to Azure Devops Repository ```$devops``` 

6.
Updates on level ```/$model``` trigger build pipeline ```$pipelines```

7.
build pipeline ```$pipelines``` builds dockerimage from Dockerfile and model artifacts from ```/$model``` and pushes container to repository

8.
```$containerrepository```in ACR ```ContainerRegManufacturingHH``` with tags: ```latest```and ```$buildid```

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
