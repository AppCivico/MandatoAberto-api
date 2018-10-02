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
    politician_entity e,
    politician_knowledge_base kb
WHERE
    e.politician_id = ? AND
    kb.politician_id = ? AND
    e.id = ANY ( kb.entities::int[] ) AND
    kb.active = true
GROUP BY e.id, e.name, e.human_name
SQL_QUERY

1;