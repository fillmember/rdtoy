lib = {}

lib.parseSearch = ( search ) ->

	result = {}
	queries = search.replace(/^\?/, '').split('&')
	for i of queries

		query = queries[i]
		split = query.split '='
		result[ split[0] ] = split[ 1 ]

	return result

lib.parse = ( url ) ->

	parser = document.createElement('a')
	parser.href = url
	return {
		protocol      :  parser.protocol
		host          :  parser.host
		hostname      :  parser.hostname
		port          :  parser.port
		pathname      :  parser.pathname
		search        :  parser.search
		searchObject  :  @parseSearch( parser.search )
		hash          :  parser.hash
	}

module.exports = lib