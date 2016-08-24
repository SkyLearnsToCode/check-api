module TeamMutations
  create_fields = {
    archived: 'bool',
    logo: 'str',
    name: '!str',
    subdomain: '!str',
    description: 'str'
  }

  update_fields = {
    archived: 'bool',
    logo: 'str',
    name: 'str',
    description: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('team', create_fields, update_fields)
end
