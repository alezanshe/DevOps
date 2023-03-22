# Ejercicios Módulo 03 - Kubernetes

## Ejercicio 1

Consta de una aplicación en `NodeJS` que guarda datos en memoria.

Para realizar este ejercicio partimos del Dockerfile proporcionado y hacemos `build`, `tag` y `push` con los siguientes comandos:

```
$ docker build . -t alezanshe/todo-app-monolith-in-mem
```

```
$ docker tag alezanshe/todo-app-monolith-in-mem alezanshe/todo-app-monolith-in-mem
```

```
$ docker push alezanshe/todo-app-monolith-in-mem
```

Una vez tenemos nuestra imagen en nuestro repositorio de DockerHub vamos a crear los manifiestos necesarios para levantar esa aplicación. Tal y como indica la imagen, necesitamos un deployment y un servicio.

El servicio será de tipo `LoadBalancer` que expondrá nuestra app al exterior. El yaml del servicio es el siguiente:

```
apiVersion: v1
kind: Service
metadata:
  name: app
spec:
  selector:
    app: app
  ports:
  - port: 3000
    targetPort: 3000
```

Ahora vamos a crear el deployment que contendrá la imagen anteriormente creada. Nos aseguraremos del puerto en el que trabaja la aplicación y que los labels y selectors hagan match para asegurarnos que el deployment se comunica con el servicio. El deployment.yaml es el siguiente:


```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
    spec:
      containers:
      - name: app
        image: alezanshe/todo-app-monolith-in-mem
        ports:
        - containerPort: 3000
```

Para correr nuestra aplicación vamos a hacer uso del binario que nos acompañará este módulo. `Kubectl` es el binario que nos permitirá dar instrucciones a nuestro cluster que está corriendo gracias a `Minikube`.

Primero vamos a correr el .yaml del servicio:

```
$ kubectl apply -f svc.yaml
```

Deberíamos ver un output como el siguiente:

```
service/app created
```

Ahora para levantar el deployment haremos lo mismo con el deployment.yaml

```
$ kubectl apply -f deployment.yaml
```

Y veremos el siguiente output:

```
deployment.apps/app created
```

Ahora para ver si nuestra aplicación esta corriendo perfectamente podemos hacer:

```
$ kubectl get pods
```

```
NAME                   READY   STATUS    RESTARTS   AGE
app-599b7b9d4b-gz6tl   1/1     Running   0          51s
```

Para comprobar que nuestro servicio está corriendo usamos:

```
$ kubectl get service
```

```
NAME         TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
app          LoadBalancer   10.102.103.238   <pending>     3000:30057/TCP   3m14s
kubernetes   ClusterIP      10.96.0.1        <none>        443/TCP          5d11h
```

Y por último para exponer nuestra aplicación ya que no será expuesta automáticamente hasta que lo indiquemos hacemos uso de:

```
$ minikube service app
```

o también podemos hacer

```
$ minikube tunnel
```

`Minbikube` abrirá un "tunel" entre nuestro host y el servicio y nos permitirá acceder a nuestra aplicación. Si nos fijamos y hacemos un `kubectl get service` ahora nuestr app tiene una `EXTERNAL-IP` la cual antes tenía un `<pending>`

```
NAME         TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)          AGE
app          LoadBalancer   10.102.103.238   10.102.103.238   3000:30057/TCP   9m6s
kubernetes   ClusterIP      10.96.0.1        <none>           443/TCP          5d11h
```

Se nos debería de abrir el explorador automáticamente y mostrarnos la aplicación en funcionamiento la cual es un app que hace de "To do list" que guarda los elementos en memoria. Si destruimos la aplicación se perderán los datos.

Para destruir todo de golpe, la aplicación, deployment, pods, servicios, etc... usamos:

```
$ kubectl delete -f .
```

## Ejercicio 2

Este ejercicio consiste en crear una aplicación que consta principalmente de dos aplicaciones que se comunicarán a través de sus servicios. La primera es la aplicación anterior de `NodeJS` pero escuchará de una base de datos `PostgreSQL` y guardará los datos en la base de datos.

El procedimiento para la creación de las imágenes es el mismo que el anterior con la diferencia de que para la creación de la base de datos se le proporcionará una base de datos ya creada.

### Base de datos `PostgreSQL`

Para levantar la base de datos necesitamos un `StatefulSet` que proporcionará alta disponibilidad al almacenamiento. En este manifiesto indicaremos el tipo de almacenamiento y la persistencia de los datos que queremos. También apuntará a un servicio de tipo `ClusterIP` y a un `ConfigMap` que contendrá la configuración y variables de entorno necesarias para su funcionamiento.

Iremos levantando los manifiestos en el mejor orden posible. Primero los relacionados a la configuración, segundo los relacionados a la red, tercero al almacenamiento y por último al deployment o statefulset.

Aplicamos `demo-db-cm.yaml` que es en el que se encuentran todas las variables de entorno y configuración en general

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-db-cm
  labels:
    app: demo-db
data:
  DB_HOST: "demo-db-svc"
  DB_USER: "postgres"
  DB_PASSWORD: "postgres"
  DB_PORT: "5432"
  DB_NAME: "todos_db"
  DB_VERSION: "10.4"
```

Aplicamos `demo-db-sc.yaml` que se encarga del tipo de almacenamiento que queramos

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: demo-db-sc
provisioner: k8s.io/minikube-hostpath
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

Aplicamos `demo-db-pv.yaml` que es el archivo que tiene el almacenamiento en una ruta con las instrucciones del tipo de almacenamiento que le indica el `StorageClass`

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: demo-db-pv
spec:
  capacity:
    storage: 5Gi
  hostPath:
    path: /data/pv01
  accessModes:
    - ReadWriteOnce
  storageClassName: demo-db-sc
```

Aplicamos `demo-db-svc.yaml` que es el servicio. En este caso se le ha asignado `clusterIP: None` lo que hará que el servicio sea de tipo `Headless`

```
apiVersion: v1
kind: Service
metadata:
  name: demo-db-svc
spec:
  selector:
    app: demo-db-svc
  clusterIP: None
  ports:
  - protocol: TCP
    port: 5432
    targetPort: 5432
```

Por último, aplicamos el StatefulSet. El yaml es parecido al de un deployment sólo que la gran diferencia es que en el deployment nos aplica un nombre aleatorio siguiendo al nombre de nuestra aplicación de tipo `app-599b7b9d4b-gz6tl` mientras que en el statefulset los nombres tienen un 0, 1, 2, 3, etc... al final de el nombre del Pod

```
NAME                                  READY   STATUS    RESTARTS   AGE
demo-app-deployment-bf7fcb774-5c9cz   1/1     Running   0          53s
demo-db-ss-0                          1/1     Running   0          53s
demo-db-ss-1                          1/1     Running   0          49s
demo-db-ss-2                          1/1     Running   0          45s
demo-db-ss-3                          1/1     Running   0          41s
demo-db-ss-4                          1/1     Running   0          37s
demo-db-ss-5                          1/1     Running   0          33s
demo-db-ss-6                          1/1     Running   0          29s
demo-db-ss-7                          1/1     Running   0          24s
demo-db-ss-8                          1/1     Running   0          20s
demo-db-ss-9                          1/1     Running   0          16s        
```

Aplicamos `demo-db-ss.yaml`

```
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: demo-db-ss
spec:
  selector:
    matchLabels:
      app: demo-db-svc
  serviceName: demo-db-svc
  replicas: 10
  template:
    metadata:
      labels:
        app: demo-db-svc
    spec:
      containers:
      - name: demo-db
        image: alezanshe/todo-app-monolith-db
        # image: postgres:10.4
        env:
          - name: DB_HOST
            valueFrom:
              configMapKeyRef:
                name: demo-app-cm
                key: DB_HOST
          - name: DB_USER
            valueFrom:
              configMapKeyRef:
                name: demo-app-cm
                key: DB_USER
          - name: DB_PASSWORD
            valueFrom:
              configMapKeyRef:
                name: demo-app-cm
                key: DB_PASSWORD
          - name: DB_PORT
            valueFrom:
              configMapKeyRef:
                name: demo-app-cm
                key: DB_PORT
          - name: DB_NAME
            valueFrom:
              configMapKeyRef:
                name: demo-app-cm
                key: DB_NAME
          - name: DB_VERSION
            valueFrom:
              configMapKeyRef:
                name: demo-app-cm
                key: DB_VERSION
        ports:
        - containerPort: 5432
          name: demo-db
        volumeMounts:
        - name: demo-db-pvc
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: demo-db-pvc
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: demo-db-sc
      resources:
        requests:
          storage: 250Mi
```

La especialidad de este tipo es que permite HA o alta dispojnibilidad. El Pod 0 siempre es el maestro y los demás son los esclavos de manera que si uno de ellos se cae, se creará automaticamente, el Pod y su almacenamiento con los datos replicados de los otros Pods.

### Aplicación en `NodeJS`

Esta aplicación consta de un configmap, un servicio y un deployment

Como en el paso anterior, vamos a ir aplicando .yaml

Aplicamos `demo-app-cm.yaml`

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-app-cm
  labels:
    app: demo-app-cm
data:
  NODE_ENV: "production"
  PORT: "3000"
  DB_HOST: "demo-db-svc"
  DB_USER: "postgres"
  DB_PASSWORD: "postgres"
  DB_PORT: "5432"
  DB_NAME: "todos_db"
  DB_VERSION: "10.4"
```

Aplicamos `demo-app-svc.yaml`

```
apiVersion: v1
kind: Service
metadata:
  name: demo-app-svc
spec:
  selector:
    app: demo-app-svc
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000
```

Aplicamos `demo-app-deployment.yaml`

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app-deployment
spec:
  selector:
    matchLabels:
      app: demo-app-svc
  template:
    metadata:
      labels:
        app: demo-app-svc
    spec:
      containers:
      - name: demo-app
        image: alezanshe/todo-app-monolith-app
        env:
          - name: NODE_ENV
            valueFrom:
              configMapKeyRef:
                name: demo-app-cm
                key: NODE_ENV
          - name: PORT
            valueFrom:
              configMapKeyRef:
                name: demo-app-cm
                key: PORT
          - name: DB_HOST
            valueFrom:
              configMapKeyRef:
                name: demo-app-cm
                key: DB_HOST
          - name: DB_USER
            valueFrom:
              configMapKeyRef:
                name: demo-app-cm
                key: DB_USER
          - name: DB_PASSWORD
            valueFrom:
              configMapKeyRef:
                name: demo-app-cm
                key: DB_PASSWORD
          - name: DB_PORT
            valueFrom:
              configMapKeyRef:
                name: demo-app-cm
                key: DB_PORT
          - name: DB_NAME
            valueFrom:
              configMapKeyRef:
                name: demo-app-cm
                key: DB_NAME
          - name: DB_VERSION
            valueFrom:
              configMapKeyRef:
                name: demo-app-cm
                key: DB_VERSION
        ports:
        - containerPort: 3000
```

La aplicación en NodeJS es la que pone el frontend en este caso, así que será la encargada de estar expuesta al exterior. Siguiente el flujo desde el exterior hasta el interior seria así:

```
demo-app-svc (LoadBalancer) -> demo-app-deployment (NodeJS) -> demo-db-svc (ClusterIP) -> demo-db-ss (PostgreSQL)
```

Vamos a correr `kubectl` para comprobar que todo está corriendo como debiera

```
$ kubectl get configmap
```

```
NAME               DATA   AGE
demo-app-cm        8      10m
demo-db-cm         6      10m
kube-root-ca.crt   1      5d12h
```

```
$ kubectl get storageclass
```

```
NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
demo-db-sc           k8s.io/minikube-hostpath   Delete          Immediate           false                  6m31s
standard (default)   k8s.io/minikube-hostpath   Delete          Immediate           false                  5d12h
```

```
$ kubectl get persistentvolume
```

```
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                              STORAGECLASS   REASON   AGE
demo-db-pv                                 5Gi        RWO            Retain           Bound    default/demo-db-pvc-demo-db-ss-0   demo-db-sc              9m17s
pvc-2e76ad33-56c7-465d-83d3-a03a5b748e05   250Mi      RWO            Delete           Bound    default/demo-db-pvc-demo-db-ss-9   demo-db-sc              8m40s
pvc-441ff516-c52a-49d9-af72-a313f379d413   250Mi      RWO            Delete           Bound    default/demo-db-pvc-demo-db-ss-1   demo-db-sc              9m13s
pvc-4b9b1d35-2756-451f-af7b-be059562c3da   250Mi      RWO            Delete           Bound    default/demo-db-pvc-demo-db-ss-5   demo-db-sc              8m57s
pvc-52ee515e-7301-4934-96a2-639bf6b777cf   250Mi      RWO            Delete           Bound    default/demo-db-pvc-demo-db-ss-7   demo-db-sc              8m48s
pvc-82528db8-b836-4860-95c1-97339c5fc013   250Mi      RWO            Delete           Bound    default/demo-db-pvc-demo-db-ss-4   demo-db-sc              9m1s
pvc-9f0b791e-4a3b-4c46-bb27-2f7555e6d696   250Mi      RWO            Delete           Bound    default/demo-db-pvc-demo-db-ss-8   demo-db-sc              8m44s
pvc-a08c4e58-1079-4f50-a315-04033afc1c64   250Mi      RWO            Delete           Bound    default/demo-db-pvc-demo-db-ss-3   demo-db-sc              9m5s
pvc-c211b507-954b-4202-b1a9-7060ea300f10   250Mi      RWO            Delete           Bound    default/demo-db-pvc-demo-db-ss-2   demo-db-sc              9m9s
pvc-fe434c30-dad7-42ee-a8fd-96612aed702b   250Mi      RWO            Delete           Bound    default/demo-db-pvc-demo-db-ss-6   demo-db-sc              8m53s
```

```
$ kubectl get persistentvolumeclaim
```

```
NAME                       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
demo-db-pvc-demo-db-ss-0   Bound    demo-db-pv                                 5Gi        RWO            demo-db-sc     9m54s
demo-db-pvc-demo-db-ss-1   Bound    pvc-441ff516-c52a-49d9-af72-a313f379d413   250Mi      RWO            demo-db-sc     9m50s
demo-db-pvc-demo-db-ss-2   Bound    pvc-c211b507-954b-4202-b1a9-7060ea300f10   250Mi      RWO            demo-db-sc     9m46s
demo-db-pvc-demo-db-ss-3   Bound    pvc-a08c4e58-1079-4f50-a315-04033afc1c64   250Mi      RWO            demo-db-sc     9m42s
demo-db-pvc-demo-db-ss-4   Bound    pvc-82528db8-b836-4860-95c1-97339c5fc013   250Mi      RWO            demo-db-sc     9m38s
demo-db-pvc-demo-db-ss-5   Bound    pvc-4b9b1d35-2756-451f-af7b-be059562c3da   250Mi      RWO            demo-db-sc     9m34s
demo-db-pvc-demo-db-ss-6   Bound    pvc-fe434c30-dad7-42ee-a8fd-96612aed702b   250Mi      RWO            demo-db-sc     9m30s
demo-db-pvc-demo-db-ss-7   Bound    pvc-52ee515e-7301-4934-96a2-639bf6b777cf   250Mi      RWO            demo-db-sc     9m25s
demo-db-pvc-demo-db-ss-8   Bound    pvc-9f0b791e-4a3b-4c46-bb27-2f7555e6d696   250Mi      RWO            demo-db-sc     9m21s
demo-db-pvc-demo-db-ss-9   Bound    pvc-2e76ad33-56c7-465d-83d3-a03a5b748e05   250Mi      RWO            demo-db-sc     9m17s      
```

```
$ kubectl get service
```

```
NAME           TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
demo-app-svc   LoadBalancer   10.101.179.225   <pending>     3000:32556/TCP   12m
demo-db-svc    ClusterIP      None             <none>        5432/TCP         12m
kubernetes     ClusterIP      10.96.0.1        <none>        443/TCP          5d12h
```

```
$ kubectl get statefulset
```

```
NAME         READY   AGE
demo-db-ss   10/10   13m
```

Si todo ha ido bien, la aplicación de NodeJS debería de mostrar 3 elementos pertenecientes a la base de datos `todo_db.sql` la cual está corriendo en el StatefulSet

El output deberia ser el siguiente:

```
configmap/demo-app-cm created
deployment.apps/demo-app-deployment created
service/demo-app-svc created
configmap/demo-db-cm created
persistentvolume/demo-db-pv created
storageclass.storage.k8s.io/demo-db-sc created
statefulset.apps/demo-db-ss created
service/demo-db-svc created
```

Para destruir todo hacemos:

```
$ kubectl delete -f .
```

Para destruir los almacenamientos:

```
$ kubectl delete pvc --all
```


## Ejercicio 3

Esta aplicación consta de una API en `NodeJS`, un frontend en `Nginx` y un `Ingress` que es una especie de gateway de peticiones el cual redirigirá las peticiones a donde le indiquemos

La API consta de un configmap, un servicio y un deployment.

El frontend consta de un servicio y un deployment.

Creamos la imagen como se nos indica y procedemos a ir aplicando los .yaml

Aplicamos `todo-front-svc.yaml`:

```
apiVersion: v1
kind: Service
metadata:
  name: todo-front-svc
spec:
  selector:
    app: todo-front-svc
  ports:
  - port: 80
    targetPort: 80
```

Aplicamos `todo-front-deployment.yaml`:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-front-deployment
spec:
  selector:
    matchLabels:
      app: todo-front-svc
  template:
    metadata:
      labels:
        app: todo-front-svc
    spec:
      containers:
      - name: todo-front
        image: alezanshe/todo-front
        ports:
        - containerPort: 80
```

Aplicamos `todo-api-cm.yaml`:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: todo-api-cm
  labels:
    app: todo-api
data:
  NODE_ENV: "production"
  PORT: "3000"
```

Aplicamos `todo-api-svc.yaml`:

```
apiVersion: v1
kind: Service
metadata:
  name: todo-api-svc
spec:
  selector:
    app: todo-api-svc
  ports:
  - port: 3000
    targetPort: 3000
```

Aplicamos `todo-api-deployment.yaml`:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-api-deployment
spec:
  selector:
    matchLabels:
      app: todo-api-svc
  template:
    metadata:
      labels:
        app: todo-api-svc
    spec:
      containers:
      - name: todo-api
        image: alezanshe/todo-api
        env:
          - name: NODE_ENV
            valueFrom:
              configMapKeyRef:
                name: todo-api-cm
                key: NODE_ENV
          - name: PORT
            valueFrom:
              configMapKeyRef:
                name: todo-api-cm
                key: PORT
        ports:
        - containerPort: 3000
```

Aplicamos el `Ingress` que gestionará las peticiones, redirigirá y mostrará las peticiones / al frontend localizado en el puerto 80, y /api en el puerto 3000. Si accedemos a `lc-todo.edu` debería de mostrarnos el frontend con la caja de texto del "To do list". Cuando guardemos los elementos, estos se almacenarán en la api. Si accediesemos a /api mediante explorador o curl, deberíamos ver algo así:

curl al frontend:

```
$ curl lc-todo.edu
```
```
<!doctype html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Document</title><script defer="defer" src="app.0b474fa3935258b2e13b.js"></script><script defer="defer" src="appStyles.c1ea380109bd9151976e.js"></script><link href="appStyles.css" rel="stylesheet"></head><body><div id="root"></div></body></html>
```

curl a la API:

```
$ curl lc-todo.edu/api
```
```
[{"title":"Prueba 1","completed":false,"id":1678909025089,"dueDate":"2023-03-15T19:37:04.857Z"},{"title":"Prueba 2","completed":false,"id":1678909028413,"dueDate":"2023-03-15T19:37:08.193Z"},{"title":"Prueba 3","completed":false,"id":1678909032589,"dueDate":"2023-03-15T19:37:12.369Z"}]
```

El output cuando corremos todos los .yaml debería ser el siguiente:

```
ingress.networking.k8s.io/todo-app created
configmap/todo-api-cm created
deployment.apps/todo-api-deployment created
service/todo-api-svc created
deployment.apps/todo-front-deployment created
service/todo-front-svc created
```

Tras terminar de usar la aplicación podemos destruirlo todo.