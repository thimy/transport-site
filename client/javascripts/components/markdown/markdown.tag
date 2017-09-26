import showdown from 'showdown'

<markdown>
    <script type="es6">
        this.converter = new showdown.Converter()
        this.element   = document.createElement('div')
        this.element.setAttribute('class', 'markdown')
        this.root.appendChild(this.element)

        this.markdownify = (markdown) => {
            return this.converter.makeHtml(markdown)
        }

        this.parse = () => {
            this.element.innerHTML = this.markdownify(this.opts.content)
        }

        this.on('mount', this.parse)
        this.on('update', this.parse)
    </script>
</markdown>
