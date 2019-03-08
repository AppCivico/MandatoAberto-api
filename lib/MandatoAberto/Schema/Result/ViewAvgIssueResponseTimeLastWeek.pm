use common::sense;

package MandatoAberto::Schema::Result::ViewAvgIssueResponseTimeLastWeek;
use base qw(DBIx::Class::Core);

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('ViewAvgIssueResponseTimeLastWeek');

__PACKAGE__->add_columns( qw( avg_response_time ) );

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(<<'SQL_QUERY');
SELECT organization_chatbot_id, round(avg( extract(epoch FROM ( updated_at - created_at ) ) / 60 )) as avg_response_time
    FROM issue
    WHERE reply IS NOT NULL AND organization_chatbot_id = ? AND created_at >= NOW() - interval '7 days'
    GROUP BY organization_chatbot_id
SQL_QUERY
1;