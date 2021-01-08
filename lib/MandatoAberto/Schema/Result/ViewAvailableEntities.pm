use common::sense;

package MandatoAberto::Schema::Result::ViewAvailableEntities;
use base qw(DBIx::Class::Core);

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('ViewAvailableEntities');

__PACKAGE__->add_columns(qw( id name human_name ));

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(<<'SQL_QUERY');
SELECT
    e.id, e.name, e.human_name
FROM
    politician_entity e
WHERE
    e.organization_chatbot_id = ? AND
    EXISTS ( SELECT 1 FROM politician_knowledge_base WHERE e.id = ANY (entities) )
SQL_QUERY

1;