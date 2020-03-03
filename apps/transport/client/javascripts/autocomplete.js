// https://github.com/babel/babel/issues/9849
require('regenerator-runtime')
const autoComplete = require('@tarekraafat/autocomplete.js/dist/js/autoComplete')

const labels = {
    region: 'région',
    aom: 'AOM',
    commune: 'commune'
}

document.onkeydown = function (evt) {
    evt = evt || window.event
    if (evt.key === 'Escape' || evt.key === 'Esc') {
        document.querySelector('#autoComplete').value = ''
        document.querySelector('#autoComplete_list').innerHTML = ''
    }
}

const autoCompletejs = new autoComplete({
    data: {
        src: async () => {
            const query = document.querySelector('#autoComplete').value
            const source = await fetch(`/api/places?q=${query}`)
            let data = await source.json()
            data = [
                {
                    name: `Rechercher ${query} dans les descriptions des jeux de données`,
                    url: `/datasets?q=${query}`
                },
                ...data
            ]
            return data
        },
        key: ['name'],
        cache: false
    },
    selector: '#autoComplete',
    threshold: 1,
    debounce: 200,
    highlight: true,
    searchEngine: (query, record) => {
        // inspired by the 'loose' searchEngine, but that always matches
        query = query.replace(/ /g, '')
        const recordLowerCase = record.toLowerCase()
        const match = []
        let searchPosition = 0
        for (let number = 0; number < recordLowerCase.length; number++) {
            let recordChar = record[number]
            if (
                searchPosition < query.length &&
                recordLowerCase[number] === query[searchPosition]
            ) {
                recordChar = `<span class="autoComplete_highlighted">${recordChar}</span>`
                searchPosition++
            }
            match.push(recordChar)
        }
        return match.join('')
    },
    maxResults: 7,
    resultsList: {
        render: true,
        container: source => {
            source.setAttribute('id', 'autoComplete_list')
        },
        destination: document.querySelector('#autoCompleteResults'),
        position: 'beforeend',
        element: 'ul'
    },
    resultItem: {
        content: (data, source) => {
            source.innerHTML = `<div><span class="autocomplete_name">${data.match}</span><span class="autocomplete_type">${labels[data.value.type] || ''}</span></div>`
        },
        element: 'li'
    },
    onSelection: feedback => {
        feedback.event.preventDefault()
        window.location = feedback.selection.value.url
    }
})
