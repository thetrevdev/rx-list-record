
describe 'app.factory', ->

  describe 'Record', ->

    Record = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        Record = $injector.get 'ksc.Record'


    it 'Does not accept property names starting with underscore', ->
      expect(-> new Record _a: 1).toThrow()

    it 'Data argument must be null/undefined/Object', ->
      expect(-> new Record 'fds').toThrow()

    it 'Options argument must be null/undefined/Object', ->
      expect(-> new Record {a: 1}, 'fds').toThrow()

    it 'Composite id, ._primaryId', ->
      record = new Record {id1: 1, id2: 2, x: 3}, idProperty: ['id1', 'id2']
      expect(record._id).toBe '1-2'
      expect(record._primaryId).toBe 1

      record = new Record {id1: 1, id2: null, x: 3}, idProperty: ['id1', 'id2']
      expect(record._id).toBe '1'

      # requires primary ID to exist
      expect(-> new Record {id2: 2, x: 3}, idProperty: ['id1', 'id2']).toThrow()

    it 'Method ._clone()', ->
      example = {id: 1, x: 2, y: {a: 3}}
      record = new Record example

      obj = record._clone true
      expect(obj).toEqual example

      example.ext = 1
      record.ext = 1
      obj = record._clone true
      expect(obj).toEqual example

      record2 = record._clone()
      expect(record).toEqual record2
      expect(record).not.toBe record2

    it 'Method ._entity()', ->
      example = {id: 1, x: 2, y: {a: 3}}
      record = new Record example
      ent = record._entity()
      expect(ent).toEqual example
      expect(ent).not.toBe example

    it 'Method ._replace()', ->
      example = {id: 1, x: 2, y: {a: 3}}
      example2 = {id: 2, x: 3, y: new Record {dds: 43, dff: 4}}
      expected = {id: 2, x: 3, y: {dds: 43, dff: 4}}
      record = new Record example
      record._replace example2
      ent = record._clone true
      expect(ent).toEqual expected
      expect(ent).not.toBe expected

    it 'Will not replace if not needed', ->
      record = new Record {a: 1}

      saved = record._saved
      record._replace {a: 1}
      expect(record._saved).toBe saved

      record._replace {a: 1, b: 2}
      expect(record._saved).not.toBe saved

      # with contract
      record = new Record null, {contract: {a: default: 1}}

      saved = record._entity()

      record._replace {}
      expect(record._entity()).toEqual saved

      record._replace {a: 2}
      expect(record._entity()).not.toEqual saved

      record._replace {}
      expect(record._entity()).toEqual saved

    it 'No _id case', ->
      record = null
      expect(-> record = new Record {}, {record: idProperty: 'x'}).not.toThrow()
      expect(record._id).toBeUndefined()

    it 'Data separation', ->
      example_sub = {a: 3}
      example = {id: 1, x: 2, y: example_sub}

      record = new Record example

      example.id    = 2
      example.ext   = 3
      example_sub.a = 4
      example_sub.x = 4

      expect(record.id).toBe 1
      expect(record.ext).toBeUndefined()
      expect(record.y.a).toBe 3
      expect(record.y.x).toBeUndefined()

    it 'Does not take functions', ->
      expect(-> new Record {id: 1, fn: ->}).toThrow()

    it 'Parent registration', ->
      record = new Record {id: 1}, null, {x: 'a'}
      expect(record._parent.x).toBe 'a'

      # Parent must be an object if specified
      expect(-> new Record {id: 1}, null, 'x').toThrow()

      # Parent_key must be string or number
      expect(-> new Record {id: 1}, null, {}, true).toThrow()

      # Parent_key requires parent object
      expect(-> new Record {id: 1}, null, null, 'x').toThrow()

    it 'Contract record', ->
      contract =
        id: {type: 'number'}
        a: {type: 'string', nullable: true}
        b: {type: 'string'}
        c: {default: ':)', nullable: true}
        d: {type: 'boolean', nullable: true}
        e: {type: 'boolean', default: true, nullable: true}
        f: {type: 'boolean'}
        g: {contract: {a: {type: 'number'}}, nullable: true}
        h: {type: 'object', contract: {
              a: {type: 'number', default: 1, nullable: true},
              b: {contract: {x: {type: 'number', nullable: true}}}}}

      record = new Record {id: 1}, {contract}

      expect(record._id).toBe 1
      expect(record.id).toBe 1
      expect(record.a).toBe null
      expect(record.b).toBe ''
      expect(record._options.contract.c.type).toBe 'string'
      expect(record.c).toBe ':)'
      expect(record.d).toBe null
      expect(record.e).toBe true
      expect(record.f).toBe false
      expect(record.g).toBe null
      expect(record.h.a).toBe 1
      expect(record.h.b.x).toBe null

      expect(-> new Record {id: 1}, {contract: 1}).toThrow()

      contract = {id: {type: 'string'}}
      expect(-> new Record {id: 1}, {contract}).toThrow()

      contract = {id: {type: 'number'}}
      expect(-> new Record {id: null}, {contract}).toThrow()

      contract = {x: {type: 'number'}}
      expect(-> new Record {id: 1}, {contract}).toThrow()

      contract = {id: {type: 'number'}, _id: {type: 'number'}}
      expect(-> new Record {id: 1}, {contract}).toThrow()

      contract = {id: {type: 'number', nullable: 1}}
      record = new Record {id: 1}, {contract}
      expect(record._options.contract.id.nullable).toBe true

      contract = {id: {type: 'number'}, x: {contract: 1}}
      expect(-> new Record {id: 1}, {contract}).toThrow()

      contract = {id: {type: 'object'}}
      expect(-> new Record null, {contract}).toThrow()

      contract = {id: {contract: {a: {type: 'number'}}, type: 'string'}}
      expect(-> new Record null, {contract}).toThrow()

      contract = {id: {type: 'joke'}}
      expect(-> new Record null, {contract}).toThrow()

      contract = {id: {contract: 1}}
      expect(-> new Record null, {contract}).toThrow()

      contract = {id: {contract: {a: {type: 'number'}}, default: null}}
      expect(-> new Record {id: 1}, {contract}).toThrow()
