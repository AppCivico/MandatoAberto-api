use common::sense;

package MandatoAberto::Schema::Result::ViewTicketMetrics;
use base qw(DBIx::Class::Core);

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('ViewTicketMetrics');

__PACKAGE__->add_columns(qw( avg_open avg_close ));

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(<<'SQL_QUERY');
WITH closed_tickets AS (
    SELECT
        id,
        organization_chatbot_id,
        created_at,
        closed_at
    FROM ticket
    WHERE
        closed_at IS NOT NULL AND
        status = 'closed'
), all_tickets AS (
    SELECT
        id,
        organization_chatbot_id,
        progress_started_at
    FROM ticket
)
SELECT
    ( SELECT AVG( c.closed_at - c.created_at ) )::interval AS avg_close,
    ( SELECT AVG( now() - progress_started_at ) FROM all_tickets WHERE organization_chatbot_id = ? )::interval AS avg_open
FROM closed_tickets c WHERE c.organization_chatbot_id = ?
SQL_QUERY
1;