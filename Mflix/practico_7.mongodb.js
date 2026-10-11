/*
1
Insertar 5 nuevos usuarios en la colección users.
Para cada nuevo usuario creado, insertar al menos un comentario realizado por el usuario en la colección comments.
*/
use("mflix");
db.users.insertMany([
    {name: 'a', email: 'a@gmail.com', password: 'a'},
    {name: 'b', email: 'b@gmail.com', password: 'b'},
    {name: 'c', email: 'c@gmail.com', password: 'c'},
    {name: 'd', email: 'd@gmail.com', password: 'd'},
    {name: 'e', email: 'e@gmail.com', password: 'e'},
]);
use("mflix");
db.comments.createMany([
    {name: 'a', email: 'a@gmail.com', movie_id: ObjectId('573a1390f29313caabcd418c'), text: 'a', date: new Date()},
    {name: 'b', email: 'b@gmail.com', movie_id: ObjectId('573a1390f29313caabcd418c'), text: 'b', date: new Date()},
    {name: 'c', email: 'c@gmail.com', movie_id: ObjectId('573a1390f29313caabcd418c'), text: 'c', date: new Date()},
    {name: 'd', email: 'd@gmail.com', movie_id: ObjectId('573a1390f29313caabcd418c'), text: 'd', date: new Date()},
    {name: 'e', email: 'e@gmail.com', movie_id: ObjectId('573a1390f29313caabcd418c'), text: 'e', date: new Date()},
]);
// ejemplo de como hacer un update bien hecho
use("mflix");
db.comments.updateMany(
    {
        movie_id: ObjectId('573a1390f29313caabcd418c'),
        name: { $in: [
            'a',
            'b',
            'c',
            'd',
            'e'
        ]},
        date: { $exists: false }
    },
    {
        $set: { date: $currentDate }
    }
);
/*
2
Listar el título, año, actores (cast), directores y rating de las 10 películas con mayor rating (“imdb.rating”) de la década del 90.
¿Cuál es el valor del rating de la película que tiene mayor rating?
(Hint: Chequear que el valor de “imdb.rating” sea de tipo “double”).
*/
use("mflix");
db.movies.find(
    {"year":{$lte:1999,$gte:1990},"imdb.rating":{$type:"double"}},
    {"_id":0,"title":1,"year":1,"cast":1,"directors":1,"imdb.rating":1})
    .sort({"imdb.rating":-1}).limit(10);
/*
3
Listar el nombre, email, texto y fecha de los comentarios que la película con id (movie_id) ObjectId("573a1399f29313caabcee886")
recibió entre los años 2014 y 2016 inclusive.
Listar ordenados por fecha.
*/
use("mflix");
db.comments.find(
    {"date":{$gte:ISODate("2014-01-01"),$lt:ISODate("2017-01-01")},"movie_id":ObjectId("573a1399f29313caabcee886")},
    {"_id":0,"movie_id":0})
    .sort({"date":1});
// Escribir una nueva consulta (modificando la anterior) para responder ¿Cuántos comentarios recibió?
use("mflix");
db.comments.find(
    {"date":{$gte:ISODate("2014-01-01"),$lt:ISODate("2017-01-01")},"movie_id":ObjectId("573a1399f29313caabcee886")})
    .count();
/*
4
Listar el nombre, id de la película, texto y fecha de los 3 comentarios más recientes realizados por el usuario con email patricia_good@fakegmail.com
*/
use("mflix");
db.comments.find(
    {"email":"patricia_good@fakegmail.com"},
    {"_id":0,"name":1,"movie_id":1,"text":1,"date":1})
    .sort({"date":-1}).limit(3);
/*
5
Listar el título, idiomas (languages), géneros, fecha de lanzamiento (released) y número de votos (“imdb.votes”)
de las películas de géneros Drama y Action (la película puede tener otros géneros adicionales), que solo están disponibles en un único idioma
y por último tengan un rating (“imdb.rating”) mayor a 9 o bien tengan una duración (runtime) de al menos 180 minutos.
Listar ordenados por fecha de lanzamiento y número de votos
*/
use("mflix");
db.movies.find( //$and:[{"genres":"Drama"},{"genres":"Action"}] (alternativa al all creo) "genres":{$all:["Drama","Action"]}
    {"genres":{$all:["Drama","Action"]},"languages":{$size:1},$or:[{"imdb.rating":{$gt:9}},{"runtime":{$gte:180}}]},
    {"_id":0,"title":1,"languages":1,"genres":1,"released":1,"imdb.votes":1})
    .sort({"released":1,"imdb.votes":-1});
/*
6
Listar el id del teatro (theaterId), estado (“location.address.state”), ciudad (“location.address.city”), y coordenadas (“location.geo.coordinates”)
de los teatros que se encuentran en algunos de los estados "CA", "NY", "TX" y el nombre de la ciudades comienza con una ‘F’.
Listar ordenados por estado y ciudad.
*/
use("mflix");
db.theaters.find(
    {"location.address.state":{$in:["CA", "NY", "TX"]},"location.address.city":{$regex:"^F"}},
    {"_id":0,"theaterId":1,"location.address.state":1,"location.address.city":1,"location.geo.coordinates":1})
    .sort({"location.address.state":1,"location.address.city":1});
/*
7
Actualizar los valores de los campos texto (text) y fecha (date) del comentario cuyo id es ObjectId("5b72236520a3277c015b3b73")
a "mi mejor comentario" y fecha actual respectivamente.
*/
use("mflix"); // esto tambien funciona con un .updateMany();
db.comments.updateOne(
    {"_id":ObjectId("5b72236520a3277c015b3b73")},
    {$set:{"text":"mi mejor comentario"},$currentDate:{"date":true}}
);
/*
8
Actualizar el valor de la contraseña del usuario cuyo email es joel.macdonel@fakegmail.com a "some password".
La misma consulta debe poder insertar un nuevo usuario en caso que el usuario no exista.
Ejecute la consulta dos veces.¿Qué operación se realiza en cada caso?
(Hint: usar upserts)
*/
use("mflix"); // La primera vez hace un upsert y la segunda vez solo hace un match, coincidente con que no haya user->lo crea->lo encuentra
db.users.updateOne(
    {"email":"joel.macdonel@fakegmail.com"},
    {$set:{"password":"some password"}},
    {upsert:true}
);
/*
9
Remover todos los comentarios realizados por el usuario cuyo email es victor_patel@fakegmail.com durante el año 1980.
*/
use("mflix");
db.comments.deleteMany( // $and:[] implicito!
    {"email":"victor_patel@fakegmail.com","date":{$gte:ISODate("1980-01-01"),$lt:ISODate("1981-01-01")}}
);
/*
10
Listar el id del restaurante (restaurant_id) y las calificaciones de los restaurantes
donde al menos una de sus calificaciones haya sido realizada entre 2014 y 2015 inclusive,
y que tenga una puntuación (score) mayor a 70 y menor o igual a 90.
*/
use("restaurantdb");
db.restaurants.find(
    {"grades":{$elemMatch:{"date":{$gte:ISODate("2014-01-01"),$lt:ISODate("2016-01-01")},"score":{$gt:70,$lte:90}}}},
    {"_id":0,"restaurant_id":1,"grades":1}
);
/*
11
Agregar dos nuevas calificaciones al restaurante cuyo id es "50018608".
A continuación se especifican las calificaciones a agregar en una sola consulta
{
	"date" : ISODate("2019-10-10T00:00:00Z"),
	"grade" : "A",
	"score" : 18
}

{
	"date" : ISODate("2020-02-25T00:00:00Z"),
	"grade" : "A",
	"score" : 21
}
*/
use("restaurantdb");
db.restaurants.updateOne(
    {"restaurant_id":"50018608"},
    {$addToSet:{"grades":{$each:[
        {"date" : ISODate("2019-10-10T00:00:00Z"),"grade" : "A","score" : 18},
        {"date" : ISODate("2020-02-25T00:00:00Z"),"grade" : "A","score" : 21}
    ]}}}
);