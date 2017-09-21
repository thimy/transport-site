<search_organizations>
<header>
<input type="search" value={ keyword }  onkeyup={ update_q } placeholder="recherche">
</header>

<ul class="organizations">
<organization each={ organizations.slice(0, 10) } name={ name }/>
</ul>

<script>
var self = this
self.organizations = []
self.keyword = ''
self.searching = false

fetch_orgs = function() {
    if (self.searching)
       return
    self.searching = true
    self.old_keyword = self.keyword
    window.fetch('http://udata.transport/api/1/organizations/?q=' + self.old_keyword)
        .then(function(response) { return response.json() })
        .then(function(data) {
            var orgs = data.data;
            self.update({organizations: orgs})
            self.searching = false
            if (self.old_keyword != self.keyword)
                fetch_orgs()
        })
}

update_q = function(e) {
    self.keyword = e.target.value
    fetch_orgs()
}

fetch_orgs()
</script>
</search_organizations>
