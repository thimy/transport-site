import '../stylesheets/app.scss'
const { addMap } = require('./leaflet')

addMap('map', '/data/home.geojson')
