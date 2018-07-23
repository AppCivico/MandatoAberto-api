use common::sense;

package MandatoAberto::Schema::Result::ViewAvgIssueResponseTime;
use base qw(DBIx::Class::Core);

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('ViewAvgIssueResponseTime');

__PACKAGE__->add_columns( qw( avg_response_time ) );

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(<<'SQL_QUERY');
SELECT politician_id, avg(updated_at - created_at) AS avg_response_time
    FROM issue
    WHERE reply IS NOT NULL AND politician_id = ?
    GROUP BY politician_id
SQL_QUERY
1;