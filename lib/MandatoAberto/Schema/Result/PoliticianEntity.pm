use utf8;
package MandatoAberto::Schema::Result::PoliticianEntity;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::PoliticianEntity

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

=head1 TABLE: C<politician_entity>

=cut

__PACKAGE__->table("politician_entity");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'politician_entity_id_seq'

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 recipient_count

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "politician_entity_id_seq",
  },
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "recipient_count",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "name",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 politician

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Politician>

=cut

__PACKAGE__->belongs_to(
  "politician",
  "MandatoAberto::Schema::Result::Politician",
  { user_id => "politician_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-08-23 10:07:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fLqIsKjnOl5idRdMfAv+/A


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub get_recipients {
    my ($self) = @_;

    my $id = $self->id;

    my $cond = \[ <<'SQL_QUERY', $id ];
 @> ARRAY[?]::integer[]
SQL_QUERY

    return $self->result_source->schema->resultset('Recipient')->search( { entities => $cond } );
}

sub knowledge_base_rs {
    my ($self) = @_;

    my $cond = \[ <<'SQL_QUERY', $self->id ];
 @> ARRAY[?]::integer[]
SQL_QUERY

    return $self->politician->politician_knowledge_bases->search( { entities => $cond } );
}

sub has_active_knowledge_base {
    my ($self) = @_;

    my $id = $self->id;

    my $knowledge_base_rs = $self->knowledge_base_rs->search( { active => 1 } );

    return $knowledge_base_rs->count > 0 ? 1 : 0;
}

sub pending_knowledge_base_types {
    my ($self) = @_;

    my @available_types = $self->result_source->schema->resultset('AvailableType')->get_column('name')->all();

    my $knowledge_base_rs = $self->knowledge_base_rs;

    my @pending_types;
    for ( my $i = 0; $i < scalar @available_types; $i++ ) {
        my $type = $available_types[$i];

        my $count = $knowledge_base_rs->search(
            {
                active => 1,
                type   => $type
            }
        )->count;

        push @pending_types, $type if $count == 0;
    }

    return @pending_types;
}

sub get_knowledge_bases_by_types {
    my ($self) = @_;

    my @available_types = $self->result_source->schema->resultset('AvailableType')->get_column('name')->all();

    my $knowledge_base_rs = $self->knowledge_base_rs;

    return [
        map {
            my $kb = $knowledge_base_rs->search( { type => $_ } )->next;

            +{
                id                    => $kb ? $kb->id                    : undef,
                active                => $kb ? $kb->active                : undef,
                type                  => $kb ? $kb->type                  : $_,
                answer                => $kb ? $kb->answer                : undef,
                updated_at            => $kb ? $kb->updated_at            : undef,
                created_at            => $kb ? $kb->created_at            : undef,
                saved_attachment_id   => $kb ? $kb->saved_attachment_id   : undef,
                saved_attachment_type => $kb ? $kb->saved_attachment_type : undef,
            }
        } @available_types
    ]
}

sub human_name {
    my ($self) = @_;

    # TODO passar isso para uma coluna no banco

    my $name;
    if ( $self->name eq 'Aborto' ) {
        $name = 'Aborto';
    }
    elsif ( $self->name eq 'Bolsa_Familia' ) {
        $name = 'Bolsa Família';
    }
    elsif ( $self->name eq 'Combate_a_corrupcao' ) {
        $name = 'Combate a Corrupção';
    }
    elsif ( $self->name eq 'Desemprego' ) {
        $name = 'Desemprego';
    }
    elsif ( $self->name eq 'Direita_ou_Esquerda' ) {
        $name = 'Direita ou Esquerda';
    }
    elsif ( $self->name eq 'Economia' ){
        $name = 'Economia';
    }
    elsif ( $self->name eq 'Educacao' ){
        $name = 'Educação';
    }
    elsif ( $self->name eq 'Emprego' ){
        $name = 'Emprego';
    }
    elsif ( $self->name eq 'Gastos_Publicos' ){
        $name = 'Gastos Públicos';
    }
    elsif ( $self->name eq 'Impostos' ){
        $name = 'Impostos';
    }
    elsif ( $self->name eq 'Infraestrutura' ){
        $name = 'Infraestrutura';
    }
    elsif ( $self->name eq 'Lava_Jato' ){
        $name = 'Lava Jato';
    }
    elsif ( $self->name eq 'Partido' ){
        $name = 'Partido';
    }
    elsif ( $self->name eq 'Politica' ){
        $name = 'Política';
    }
    elsif ( $self->name eq 'Politica_Externa' ){
        $name = 'Política Externa';
    }
    elsif ( $self->name eq 'Presidente' ){
        $name = 'Presidente';
    }
    elsif ( $self->name eq 'Previdencia_Social' ){
        $name = 'Previdência Social';
    }
    elsif ( $self->name eq 'Privatizacao' ){
        $name = 'Privatização';
    }
    elsif ( $self->name eq 'Programas_Sociais' ){
        $name = 'Programas Sociais';
    }
    elsif ( $self->name eq 'Reforma_Trabalhista' ){
        $name = 'Reforma Trabalhista';
    }
    elsif ( $self->name eq 'Saude' ){
        $name = 'Saúde';
    }
    elsif ( $self->name eq 'Seguranca' ){
        $name = 'Segurança';
    }
    elsif ( $self->name eq 'Direitos_Humanos' ){
        $name = 'Direitos Humanos';
    }
    elsif ( $self->name eq 'Proposta' ) {
        $name = 'Proposta';
    }
    elsif ( $self->name eq 'direitos_animais' ) {
        $name = 'direitos dos animais';
    }
    elsif ( $self->name eq 'ciencia_tecnologia_inovacao' ) {
        $name = 'ciência, tecnologia e inovação';
    }
    elsif ( $self->name eq 'empreendedorismo_tecnologias' ) {
        $name = 'empreendedorismo e novas tecnologias';
    }
    elsif ( $self->name eq 'primeira_infancia' ) {
        $name = 'primeira infância ';
    }
    elsif ( $self->name eq 'forcas_armadas' ) {
        $name = 'forças armadas';
    }
    elsif ( $self->name eq 'atuacao_forcas_armadas' ) {
        $name = 'atuação das forças armadas';
    }
    elsif ( $self->name eq 'reforma_politica' ) {
        $name = 'reforma política';
    }
    elsif ( $self->name eq 'combate_privilegios' ) {
        $name = 'combate de privilégios';
    }
    elsif ( $self->name eq 'privatizacoes' ) {
        $name = 'privatizações';
    }
    elsif ( $self->name eq 'administracao_publica' ) {
        $name = 'administração pública';
    }
    elsif ( $self->name eq 'governo_digital' ) {
        $name = 'governo digital ';
    }
    elsif ( $self->name eq 'composicao_governo' ) {
        $name = 'composição de governo';
    }
    elsif ( $self->name eq 'relação_congresso' ) {
        $name = 'relação com o congresso';
    }
    elsif ( $self->name eq 'governabilidade' ) {
        $name = 'governabilidade';
    }
    elsif ( $self->name eq 'sistema_financeiro' ) {
        $name = 'sistema financeiro';
    }
    elsif ( $self->name eq 'etica_politica' ) {
        $name = 'Ética na política';
    }
    elsif ( $self->name eq 'etica_politica' ) {
        $name = 'combate de privilégios';
    }
    elsif ( $self->name eq 'combate_corrupcao' ) {
        $name = 'combate à corrupção';
    }
    elsif ( $self->name eq 'governo_transparente' ) {
        $name = 'governo transparente';
    }
    elsif ( $self->name eq 'privilegios_judiciario' ) {
        $name = 'privilégios do judiciário';
    }
    elsif ( $self->name eq 'conducao_economia' ) {
        $name = 'Condução da economia';
    }
    elsif ( $self->name eq 'refis' ) {
        $name = 'refis';
    }
    elsif ( $self->name eq 'privilegios_previdencia' ) {
        $name = 'privilégios na previdência';
    }
    elsif ( $self->name eq 'inadimplencia_empresas' ) {
        $name = 'inadimplência de empresas';
    }
    elsif ( $self->name eq 'pacto_federativo' ) {
        $name = 'pacto federativo';
    }
    elsif ( $self->name eq 'presidencialismo_coalizao' ) {
        $name = 'presidencialismo de coalizão';
    }
    elsif ( $self->name eq 'politicas_sociais' ) {
        $name = 'políticas sociais';
    }
    elsif ( $self->name eq 'inclusao_digital' ) {
        $name = 'inclusão digital';
    }
    elsif ( $self->name eq 'desenvolvimento_sustentavel' ) {
        $name = 'desenvolvimento sustentável';
    }
    elsif ( $self->name eq 'diversificacao_energetica' ) {
        $name = 'diversificação da matriz energética';
    }
    elsif ( $self->name eq 'economia_baixo_carbono' ) {
        $name = 'economia de baixo carbono e biocombustíveis ';
    }
    elsif ( $self->name eq 'setor_eletrico' ) {
        $name = 'setor elétrico';
    }
    elsif ( $self->name eq 'concessoes_licitacoes' ) {
        $name = 'concessões e licitações';
    }
    elsif ( $self->name eq 'tamanho_estado' ) {
        $name = 'tamanho do Estado';
    }
    elsif ( $self->name eq 'abertura_economia' ) {
        $name = 'abertura da economia';
    }
    elsif ( $self->name eq 'setor_eletrico' ) {
        $name = 'diversificação da matriz energética';
    }
    elsif ( $self->name eq 'propostas_povos_tradicionais' ) {
        $name = 'propostas para povos tradicionais ';
    }
    elsif ( $self->name eq 'idosos' ) {
        $name = 'políticas para idosos';
    }
    elsif ( $self->name eq 'propostas_LGBT' ) {
        $name = 'propostas para LGBTs';
    }
    elsif ( $self->name eq 'proposta_mulheres' ) {
        $name = 'propostas para mulheres ';
    }
    elsif ( $self->name eq 'propostas_populacao_negra' ) {
        $name = 'propostas para a população negra';
    }
    elsif ( $self->name eq 'politica_assistencia_social' ) {
        $name = 'política de assistência social';
    }
    elsif ( $self->name eq 'superacao_pobreza' ) {
        $name = 'superação da pobreza';
    }
    elsif ( $self->name eq 'escola_integral' ) {
        $name = 'escola integral';
    }
    elsif ( $self->name eq 'propostas_educacao' ) {
        $name = 'propostas para a educação';
    }
    elsif ( $self->name eq 'superacao_analfabetismo' ) {
        $name = 'superação do analfabetismo ';
    }
    elsif ( $self->name eq 'acoes_afirmativas' ) {
        $name = 'ações afirmativas';
    }
    elsif ( $self->name eq 'eficiencia_gastos_publicos' ) {
        $name = 'eficiência nos gastos públicos';
    }
    elsif ( $self->name eq 'investimentos_setor_privado' ) {
        $name = 'atrair investimentos do setor privado';
    }
    elsif ( $self->name eq 'infraestrutura' ) {
        $name = 'infraestrutura';
    }
    elsif ( $self->name eq 'estar_sumida' ) {
        $name = 'estar sumida';
    }
    elsif ( $self->name eq 'aborto' ) {
        $name = ' aborto';
    }
    elsif ( $self->name eq 'aborto' ) {
        $name = 'posição sobre o aborto';
    }
    elsif ( $self->name eq 'espingarda' ) {
        $name = 'possuia espingarda';
    }
    elsif ( $self->name eq 'porte_arma' ) {
        $name = 'porte de arma';
    }
    elsif ( $self->name eq 'maconha' ) {
        $name = 'maconha';
    }
    elsif ( $self->name eq 'politica_externa' ) {
        $name = 'política externa';
    }
    elsif ( $self->name eq 'relacoes_exteriores' ) {
        $name = 'relações exteriores';
    }
    elsif ( $self->name eq 'Brasil_mundo' ) {
        $name = 'papel do Brasil no mundo';
    }
    elsif ( $self->name eq 'carga_tributaria' ) {
        $name = 'economia de baixo carbono';
    }
    elsif ( $self->name eq 'superacao_carga_tributaria' ) {
        $name = 'superação da carga tributária';
    }
    elsif ( $self->name eq 'transparencia_governo' ) {
        $name = 'transparência no governo';
    }
    elsif ( $self->name eq 'reforma' ) {
        $name = ' previdência reforma da previdência';
    }
    elsif ( $self->name eq 'reforma_tributaria' ) {
        $name = 'reforma tributária';
    }
    elsif ( $self->name eq 'reforma' ) {
        $name = 'lítica reforma política';
    }
    elsif ( $self->name eq 'gestao_municipios' ) {
        $name = 'gestão dos municípios';
    }
    elsif ( $self->name eq 'tributacao_dividendos' ) {
        $name = 'tributação sobre dividendos ';
    }
    elsif ( $self->name eq 'politica_economica' ) {
        $name = 'política econômica';
    }
    elsif ( $self->name eq 'renovacao_politica' ) {
        $name = 'renovação política';
    }
    elsif ( $self->name eq 'aposentadoria' ) {
        $name = 'aposentadoria';
    }
    elsif ( $self->name eq 'agronegocio' ) {
        $name = 'agronegócio';
    }
    elsif ( $self->name eq 'uso_terra' ) {
        $name = 'uso da terra e cadastros rurais';
    }
    elsif ( $self->name eq 'agropecuaria_mercado_exterior' ) {
        $name = 'agropecuária no mercado exterior';
    }
    elsif ( $self->name eq 'assentamentos_rurais' ) {
        $name = 'assentamentos rurais';
    }
    elsif ( $self->name eq 'regularizacao_terras' ) {
        $name = 'regularização de terras';
    }
    elsif ( $self->name eq 'tecnologias_agricolas' ) {
        $name = 'tecnologias agrícolas';
    }
    elsif ( $self->name eq 'impostos_rurais' ) {
        $name = 'impostos rurais';
    }
    elsif ( $self->name eq 'pronaf' ) {
        $name = 'pronaf';
    }
    elsif ( $self->name eq 'agricultura_familiar' ) {
        $name = 'agricultura familiar';
    }
    elsif ( $self->name eq 'agrotoxicos' ) {
        $name = 'agrotóxicos';
    }
    elsif ( $self->name eq 'quilombolas' ) {
        $name = 'demarcações de terras indígenas e quilombolas';
    }
    elsif ( $self->name eq 'regularizacao_terras_indigenas' ) {
        $name = 'regularização de terras indígenas';
    }
    elsif ( $self->name eq 'saneamento_basico' ) {
        $name = 'saneamento básico';
    }
    elsif ( $self->name eq 'esporte' ) {
        $name = 'esporte';
    }
    elsif ( $self->name eq 'propostas_saúde' ) {
        $name = 'SUS e propostas para a saúde';
    }
    elsif ( $self->name eq 'atencao_basica' ) {
        $name = 'atenção básica e Saúde da Família';
    }
    elsif ( $self->name eq 'Saude_Familia' ) {
        $name = 'saúde da fam';
    }
    elsif ( $self->name eq 'melhoria_saude' ) {
        $name = 'melhoria da saúde';
    }
    elsif ( $self->name eq 'saude_mental' ) {
        $name = 'saúde mental';
    }
    elsif ( $self->name eq 'saude_LGBTI' ) {
        $name = 'saúde para LGBTI';
    }
    elsif ( $self->name eq 'saude_mulheres' ) {
        $name = 'saúde para mulheres';
    }
    elsif ( $self->name eq 'Qualidade_vida_idosos' ) {
        $name = 'Qualidade de vida para idosos';
    }
    elsif ( $self->name eq 'qualidade_vida' ) {
        $name = 'qualidade de vida';
    }
    elsif ( $self->name eq 'sistema_prisional' ) {
        $name = 'sistema prisional';
    }
    elsif ( $self->name eq 'Seguranca_publica' ) {
        $name = 'Segurança pública';
    }
    elsif ( $self->name eq 'desenvolvimento_sustentavel' ) {
        $name = 'desenvolvimento sustentável';
    }
    elsif ( $self->name eq 'Petrobras' ) {
        $name = 'Petrobras';
    }
    elsif ( $self->name eq 'politica_cidades' ) {
        $name = 'política para cidades';
    }
    elsif ( $self->name eq 'programas_habitacao' ) {
        $name = 'programas de habitação';
    }
    elsif ( $self->name eq 'mudancas_climaticas' ) {
        $name = 'mudanças climáticas';
    }
    elsif ( $self->name eq 'fomento_pesquisa' ) {
        $name = 'fomento de pesquisa';
    }
    elsif ( $self->name eq 'bem_estar_animal' ) {
        $name = 'bem estar animal ';
    }
    elsif ( $self->name eq 'pessoas_deficencia' ) {
        $name = 'pessoas com deficiência';
    }
    elsif ( $self->name eq 'demarcacao_terras_indigenas' ) {
        $name = 'demarcação de terras indígenas ';
    }
    elsif ( $self->name eq 'propostas_juventude' ) {
        $name = 'propostas para a juventude ';
    }
    elsif ( $self->name eq 'propostas_cultura' ) {
        $name = 'propostas para a cultura';
    }
    elsif ( $self->name eq 'propostas_criancas' ) {
        $name = 'propostas para crianças';
    }
    elsif ( $self->name eq 'Infraestrutura' ) {
        $name = 'Infraestrutura'
    }
    elsif ( $self->name eq 'propostas_saude' ) {
        $name = 'Propostas para a saúde';
    }
    elsif ( $self->name eq 'relacao_congresso' ) {
        $name = 'Relação com o congresso';
    }
	elsif ( $self->name eq 'geracao_empregos' ) {
		$name = 'Geração de empregos';
	}
	elsif ( $self->name eq 'educacao' ) {
		$name = 'Educação';
	}
	elsif ( $self->name eq 'saude' ) {
		$name = 'Saúde';
	}
	elsif ( $self->name eq 'meio_ambiente' ) {
		$name = 'Meio Ambiente';
	}
    elsif ( $self->name eq 'direitos_humanos' ) {
        $name = 'Direitos humanos';
    }
    elsif ( $self->name eq 'direitos_sociais' ) {
        $name = 'Direitos sociais';
    }

    return $name;
}

__PACKAGE__->meta->make_immutable;
1;
