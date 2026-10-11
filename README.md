# BDD 2026

## Como correr el MONGODB DE MIERDA

- Tener docker instalado y andando
- Correr el siguiente codigo en cualquier lugar
```bash
sudo docker pull mongo:9
sudo docker run --name mongo-labs \
  -d \
  -p 127.0.0.1:27017:27017 \
  -e GLIBC_TUNABLES=glibc.pthread.rseq=1 \
  mongo:9
```
- Conectarse al container con el servicio con la extension de vscode (usa la opcion de 'connect')
```
mongodb://127.0.0.1:27017
```
- Correr el siguiente codigo en una terminal en la ruta/path donde este el archivo de creacion de la bdd
  - Si es desde un tar.gz descomprimido o carpeta
```bash
sudo docker cp ./<nombre_de_la_BDD> mongo-labs:/tmp/<nombre_de_la_BDD> && sudo docker exec -it mongo-labs mongorestore --drop --gzip --db <nombre_de_la_BDD> /tmp/<nombre_de_la_BDD>
```
  - Si es desde un JSON (puede que haga falta hacer mas de 1 linea de collection)
```bash
sudo docker cp <nombre_de_la_BDD>.json mongo-labs:/tmp/<nombre_de_la_BDD>.json
sudo docker exec mongo-labs mongoimport \
  --db <nombre_de_la_BDD> \
  --collection <nombre_de_la_collection> \
  --drop \
  --file /tmp/<nombre_de_la_BDD>.json
```
- Listo!
- Mentira wachin, ahora te toca crear el archivo del practico/parcial en la carpeta que quieras con el formato `nombre.mongodb.js`
- Arriba de todo en el archivo te va a salir una opcion para conectarte, hacele click y selecciona `127.0.0.1:27017` (que deberia ser tu unica opcion si no sos un wachin)
- Acordate de usar `use("<nombre_de_la_BDD>")` antes de cada query
- Ahora si terminamos
- NAH, yo se que queres seguir leyendome
- Para correr cualquier query hace estos pasos
  - Selecciona el codigo en el vsc
  - `Ctrl` + `Alt` + `S`
  - Dale a `Yes`
  - Se feliz (si sos tan bueno que te ande a la primera)

## Tips de la syntaxis

Existen los `$<funcion>` que funcionan como se les canta el tuje, asi que fijate de tener ejemplos o formas alternativas con ellos, punto aparte, no te olvides de usar simpre `:` despues de usar casi cualquier cosa, los `$and:[]` suelen ser implicitos en muchos casos al igual que los `$eq:`.