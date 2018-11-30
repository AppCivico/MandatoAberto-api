package MandatoAberto::Schema::ResultSet::PoliticianEntity;
use common::sense;
use Moose;
use namespace::autoclean;

use MandatoAberto::Utils qw( is_test );

use WebService::Dialogflow;

extends "DBIx::Class::ResultSet";

has _dialogflow => (
    is         => "ro",
    isa        => "WebService::Dialogflow",
    lazy_build => 1,
);

sub sync_dialogflow {
    my ($self) = @_;

    my $politician_rs;
    if ( is_test() ) {
		$politician_rs = $self->result_source->schema->resultset('Politician');
    }
    else {
		$politician_rs = $self->result_source->schema->resultset('Politician')->search({ 'user.email' => 'appcivicotest@email.com' },{ prefetch => 'user' });
    }

    my $project_id      = 'mandato-aberto-copy';
    my $last_project_id = '';

    my @entities_names;
    my $res;

    $self->result_source->schema->txn_do(
        sub{
            while ( my $politician = $politician_rs->next() ) {
                my $organization_chatbot = $politician->user->organization->organization_chatbots->next;
				my $chatbot_config       = $organization_chatbot->organization_chatbot_general_config if $organization_chatbot;
                use DDP; p $chatbot_config;
                if ( $chatbot_config && $chatbot_config->dialogflow_project_id ) {
                    $project_id = $chatbot_config->dialogflow_project_id;
                }

                $res             = $self->_dialogflow->get_intents( dialogflow_project_id => $project_id ) if $last_project_id ne $project_id;
                $last_project_id = $project_id;

				for my $entity ( @{ $res->{intents} } ) {
					my $name = $entity->{displayName};

					if ( $self->skip_intent($name) == 0 ) {
						$name = lc $name;
						push @entities_names, $name;
					}
				}

                for my $entity_name (@entities_names) {
                    $self->find_or_create(
                        {
                            politician_id => $politician->id,
                            name          => $entity_name
                        }
                    );
                }
            }
        }
    );

    return 1;
}

sub sync_dialogflow_one_politician {
    my ($self, $politician_id) = @_;

    my @entities_names;
    my $res = $self->_dialogflow->get_intents;

    for my $entity ( @{ $res->{intents} } ) {
        my $name = $entity->{displayName};

        if ( $self->skip_intent($name) == 0 ) {
            $name = lc $name;
            push @entities_names, $name;
        }
    }

    $self->result_source->schema->txn_do(
        sub{
            for my $entity_name (@entities_names) {
                $self->find_or_create(
                    {
                        politician_id => $politician_id,
                        name          => $entity_name
                    }
                );
            }
        }
    );

    return 1;
}

sub skip_intent {
    my ($self, $name) = @_;

    my @non_theme_intents = qw( Fallback Agradecimento Contatos FaleConosco Pergunta Saudação Trajetoria Voluntário Participar );

    my $skip_intent = grep { $_ eq $name } @non_theme_intents;

    return $skip_intent;
}

sub entity_exists {
    my ($self, $name) = @_;

    $name = lc $name;

    return $self->search(
        {
            '-and' => [
                \[ <<'SQL_QUERY', $name ],
                    EXISTS( SELECT 1 FROM politician_entity WHERE name = ? )
SQL_QUERY
            ],
        }
    )->count > 0 ? 1 : 0;
}

sub entities_with_available_knowledge_bases {
    my ($self) = @_;

    return $self->search(
        \[ <<'SQL_QUERY' ],

SQL_QUERY
    );
}

sub _build__dialogflow { WebService::Dialogflow->instance }

sub find_human_name {
    my ($self, $intent) = @_;

    my $name;
    if ( $intent eq 'aborto' ) {
        $name = 'aborto';
    }
    elsif ( $intent eq 'bolsa_familia' ) {
        $name = 'bolsa família';
    }
    elsif ( $intent eq 'combate_a_corrupcao' ) {
        $name = 'combate a corrupção';
    }
    elsif ( $intent eq 'desemprego' ) {
        $name = 'desemprego';
    }
    elsif ( $intent eq 'direita_ou_esquerda' ) {
        $name = 'direita ou esquerda';
    }
    elsif ( $intent eq 'economia' ){
        $name = 'economia';
    }
    elsif ( $intent eq 'educacao' ){
        $name = 'educação';
    }
    elsif ( $intent eq 'emprego' ){
        $name = 'emprego';
    }
    elsif ( $intent eq 'gastos_publicos' ){
        $name = 'gastos públicos';
    }
    elsif ( $intent eq 'impostos' ){
        $name = 'impostos';
    }
    elsif ( $intent eq 'infraestrutura' ){
        $name = 'infraestrutura';
    }
    elsif ( $intent eq 'lava_jato' ){
        $name = 'lava jato';
    }
    elsif ( $intent eq 'partido' ){
        $name = 'partido';
    }
    elsif ( $intent eq 'politica' ){
        $name = 'política';
    }
    elsif ( $intent eq 'politica_externa' ){
        $name = 'política externa';
    }
    elsif ( $intent eq 'presidente' ){
        $name = 'presidente';
    }
    elsif ( $intent eq 'previdencia_social' ){
        $name = 'previdência social';
    }
    elsif ( $intent eq 'privatizacao' ){
        $name = 'privatização';
    }
    elsif ( $intent eq 'programas_sociais' ){
        $name = 'programas sociais';
    }
    elsif ( $intent eq 'reforma_trabalhista' ){
        $name = 'reforma trabalhista';
    }
    elsif ( $intent eq 'saude' ){
        $name = 'saúde';
    }
    elsif ( $intent eq 'seguranca' ){
        $name = 'segurança';
    }
    elsif ( $intent eq 'direitos_humanos' ){
        $name = 'direitos humanos';
    }
    elsif ( $intent eq 'proposta' ) {
        $name = 'proposta';
    }
    elsif ( $intent eq 'direitos_animais' ) {
        $name = 'direitos dos animais';
    }
    elsif ( $intent eq 'ciencia_tecnologia_inovacao' ) {
        $name = 'ciência, tecnologia e inovação';
    }
    elsif ( $intent eq 'empreendedorismo_tecnologias' ) {
        $name = 'empreendedorismo e novas tecnologias';
    }
    elsif ( $intent eq 'primeira_infancia' ) {
        $name = 'primeira infância ';
    }
    elsif ( $intent eq 'forcas_armadas' ) {
        $name = 'forças armadas';
    }
    elsif ( $intent eq 'atuacao_forcas_armadas' ) {
        $name = 'atuação das forças armadas';
    }
    elsif ( $intent eq 'reforma_politica' ) {
        $name = 'reforma política';
    }
    elsif ( $intent eq 'combate_privilegios' ) {
        $name = 'combate de privilégios';
    }
    elsif ( $intent eq 'privatizacoes' ) {
        $name = 'privatizações';
    }
    elsif ( $intent eq 'administracao_publica' ) {
        $name = 'administração pública';
    }
    elsif ( $intent eq 'governo_digital' ) {
        $name = 'governo digital ';
    }
    elsif ( $intent eq 'composicao_governo' ) {
        $name = 'composição de governo';
    }
    elsif ( $intent eq 'relação_congresso' ) {
        $name = 'relação com o congresso';
    }
    elsif ( $intent eq 'governabilidade' ) {
        $name = 'governabilidade';
    }
    elsif ( $intent eq 'sistema_financeiro' ) {
        $name = 'sistema financeiro';
    }
    elsif ( $intent eq 'etica_politica' ) {
        $name = 'ética na política';
    }
    elsif ( $intent eq 'etica_politica' ) {
        $name = 'combate de privilégios';
    }
    elsif ( $intent eq 'combate_corrupcao' ) {
        $name = 'combate à corrupção';
    }
    elsif ( $intent eq 'governo_transparente' ) {
        $name = 'governo transparente';
    }
    elsif ( $intent eq 'privilegios_judiciario' ) {
        $name = 'privilégios do judiciário';
    }
    elsif ( $intent eq 'conducao_economia' ) {
        $name = 'condução da economia';
    }
    elsif ( $intent eq 'refis' ) {
        $name = 'refis';
    }
    elsif ( $intent eq 'privilegios_previdencia' ) {
        $name = 'privilégios na previdência';
    }
    elsif ( $intent eq 'inadimplencia_empresas' ) {
        $name = 'inadimplência de empresas';
    }
    elsif ( $intent eq 'pacto_federativo' ) {
        $name = 'pacto federativo';
    }
    elsif ( $intent eq 'presidencialismo_coalizao' ) {
        $name = 'presidencialismo de coalizão';
    }
    elsif ( $intent eq 'politicas_sociais' ) {
        $name = 'políticas sociais';
    }
    elsif ( $intent eq 'inclusao_digital' ) {
        $name = 'inclusão digital';
    }
    elsif ( $intent eq 'desenvolvimento_sustentavel' ) {
        $name = 'desenvolvimento sustentável';
    }
    elsif ( $intent eq 'diversificacao_energetica' ) {
        $name = 'diversificação da matriz energética';
    }
    elsif ( $intent eq 'economia_baixo_carbono' ) {
        $name = 'economia de baixo carbono e biocombustíveis ';
    }
    elsif ( $intent eq 'setor_eletrico' ) {
        $name = 'setor elétrico';
    }
    elsif ( $intent eq 'concessoes_licitacoes' ) {
        $name = 'concessões e licitações';
    }
    elsif ( $intent eq 'tamanho_estado' ) {
        $name = 'tamanho do estado';
    }
    elsif ( $intent eq 'abertura_economia' ) {
        $name = 'abertura da economia';
    }
    elsif ( $intent eq 'setor_eletrico' ) {
        $name = 'diversificação da matriz energética';
    }
    elsif ( $intent eq 'propostas_povos_tradicionais' ) {
        $name = 'propostas para povos tradicionais ';
    }
    elsif ( $intent eq 'idosos' ) {
        $name = 'políticas para idosos';
    }
    elsif ( $intent eq 'propostas_lgbt' ) {
        $name = 'propostas para lgbts';
    }
    elsif ( $intent eq 'proposta_mulheres' ) {
        $name = 'propostas para mulheres ';
    }
    elsif ( $intent eq 'propostas_populacao_negra' ) {
        $name = 'propostas para a população negra';
    }
    elsif ( $intent eq 'politica_assistencia_social' ) {
        $name = 'política de assistência social';
    }
    elsif ( $intent eq 'superacao_pobreza' ) {
        $name = 'superação da pobreza';
    }
    elsif ( $intent eq 'escola_integral' ) {
        $name = 'escola integral';
    }
    elsif ( $intent eq 'propostas_educacao' ) {
        $name = 'propostas para a educação';
    }
    elsif ( $intent eq 'superacao_analfabetismo' ) {
        $name = 'superação do analfabetismo ';
    }
    elsif ( $intent eq 'acoes_afirmativas' ) {
        $name = 'ações afirmativas';
    }
    elsif ( $intent eq 'eficiencia_gastos_publicos' ) {
        $name = 'eficiência nos gastos públicos';
    }
    elsif ( $intent eq 'investimentos_setor_privado' ) {
        $name = 'atrair investimentos do setor privado';
    }
    elsif ( $intent eq 'infraestrutura' ) {
        $name = 'infraestrutura';
    }
    elsif ( $intent eq 'estar_sumida' ) {
        $name = 'estar sumida';
    }
    elsif ( $intent eq 'aborto' ) {
        $name = ' aborto';
    }
    elsif ( $intent eq 'aborto' ) {
        $name = 'posição sobre o aborto';
    }
    elsif ( $intent eq 'espingarda' ) {
        $name = 'possuia espingarda';
    }
    elsif ( $intent eq 'porte_arma' ) {
        $name = 'porte de arma';
    }
    elsif ( $intent eq 'maconha' ) {
        $name = 'maconha';
    }
    elsif ( $intent eq 'politica_externa' ) {
        $name = 'política externa';
    }
    elsif ( $intent eq 'relacoes_exteriores' ) {
        $name = 'relações exteriores';
    }
    elsif ( $intent eq 'brasil_mundo' ) {
        $name = 'papel do brasil no mundo';
    }
    elsif ( $intent eq 'carga_tributaria' ) {
        $name = 'economia de baixo carbono';
    }
    elsif ( $intent eq 'superacao_carga_tributaria' ) {
        $name = 'superação da carga tributária';
    }
    elsif ( $intent eq 'transparencia_governo' ) {
        $name = 'transparência no governo';
    }
    elsif ( $intent eq 'reforma' ) {
        $name = ' previdência reforma da previdência';
    }
    elsif ( $intent eq 'reforma_tributaria' ) {
        $name = 'reforma tributária';
    }
    elsif ( $intent eq 'reforma' ) {
        $name = 'lítica reforma política';
    }
    elsif ( $intent eq 'gestao_municipios' ) {
        $name = 'gestão dos municípios';
    }
    elsif ( $intent eq 'tributacao_dividendos' ) {
        $name = 'tributação sobre dividendos ';
    }
    elsif ( $intent eq 'politica_economica' ) {
        $name = 'política econômica';
    }
    elsif ( $intent eq 'renovacao_politica' ) {
        $name = 'renovação política';
    }
    elsif ( $intent eq 'aposentadoria' ) {
        $name = 'aposentadoria';
    }
    elsif ( $intent eq 'agronegocio' ) {
        $name = 'agronegócio';
    }
    elsif ( $intent eq 'uso_terra' ) {
        $name = 'uso da terra e cadastros rurais';
    }
    elsif ( $intent eq 'agropecuaria_mercado_exterior' ) {
        $name = 'agropecuária no mercado exterior';
    }
    elsif ( $intent eq 'assentamentos_rurais' ) {
        $name = 'assentamentos rurais';
    }
    elsif ( $intent eq 'regularizacao_terras' ) {
        $name = 'regularização de terras';
    }
    elsif ( $intent eq 'tecnologias_agricolas' ) {
        $name = 'tecnologias agrícolas';
    }
    elsif ( $intent eq 'impostos_rurais' ) {
        $name = 'impostos rurais';
    }
    elsif ( $intent eq 'pronaf' ) {
        $name = 'pronaf';
    }
    elsif ( $intent eq 'agricultura_familiar' ) {
        $name = 'agricultura familiar';
    }
    elsif ( $intent eq 'agrotoxicos' ) {
        $name = 'agrotóxicos';
    }
    elsif ( $intent eq 'quilombolas' ) {
        $name = 'demarcações de terras indígenas e quilombolas';
    }
    elsif ( $intent eq 'regularizacao_terras_indigenas' ) {
        $name = 'regularização de terras indígenas';
    }
    elsif ( $intent eq 'saneamento_basico' ) {
        $name = 'saneamento básico';
    }
    elsif ( $intent eq 'esporte' ) {
        $name = 'esporte';
    }
    elsif ( $intent eq 'propostas_saúde' ) {
        $name = 'sus e propostas para a saúde';
    }
    elsif ( $intent eq 'atencao_basica' ) {
        $name = 'atenção básica e saúde da família';
    }
    elsif ( $intent eq 'saude_familia' ) {
        $name = 'saúde da fam';
    }
    elsif ( $intent eq 'melhoria_saude' ) {
        $name = 'melhoria da saúde';
    }
    elsif ( $intent eq 'saude_mental' ) {
        $name = 'saúde mental';
    }
    elsif ( $intent eq 'saude_lgbti' ) {
        $name = 'saúde para lgbti';
    }
    elsif ( $intent eq 'saude_mulheres' ) {
        $name = 'saúde para mulheres';
    }
    elsif ( $intent eq 'qualidade_vida_idosos' ) {
        $name = 'qualidade de vida para idosos';
    }
    elsif ( $intent eq 'qualidade_vida' ) {
        $name = 'qualidade de vida';
    }
    elsif ( $intent eq 'sistema_prisional' ) {
        $name = 'sistema prisional';
    }
    elsif ( $intent eq 'seguranca_publica' ) {
        $name = 'segurança pública';
    }
    elsif ( $intent eq 'desenvolvimento_sustentavel' ) {
        $name = 'desenvolvimento sustentável';
    }
    elsif ( $intent eq 'petrobras' ) {
        $name = 'petrobras';
    }
    elsif ( $intent eq 'politica_cidades' ) {
        $name = 'política para cidades';
    }
    elsif ( $intent eq 'programas_habitacao' ) {
        $name = 'programas de habitação';
    }
    elsif ( $intent eq 'mudancas_climaticas' ) {
        $name = 'mudanças climáticas';
    }
    elsif ( $intent eq 'fomento_pesquisa' ) {
        $name = 'fomento de pesquisa';
    }
    elsif ( $intent eq 'bem_estar_animal' ) {
        $name = 'bem estar animal ';
    }
    elsif ( $intent eq 'pessoas_deficencia' ) {
        $name = 'pessoas com deficiência';
    }
    elsif ( $intent eq 'demarcacao_terras_indigenas' ) {
        $name = 'demarcação de terras indígenas ';
    }
    elsif ( $intent eq 'propostas_juventude' ) {
        $name = 'propostas para a juventude ';
    }
    elsif ( $intent eq 'propostas_cultura' ) {
        $name = 'propostas para a cultura';
    }
    elsif ( $intent eq 'propostas_criancas' ) {
        $name = 'propostas para crianças';
    }
    elsif ( $intent eq 'infraestrutura' ) {
        $name = 'infraestrutura'
    }
    elsif ( $intent eq 'propostas_saude' ) {
        $name = 'propostas para a saúde';
    }
    elsif ( $intent eq 'relacao_congresso' ) {
        $name = 'relação com o congresso';
    }
    elsif ( $intent eq 'geracao_empregos' ) {
        $name = 'geração de empregos';
    }
    elsif ( $intent eq 'educacao' ) {
        $name = 'educação';
    }
    elsif ( $intent eq 'saude' ) {
        $name = 'saúde';
    }
    elsif ( $intent eq 'meio_ambiente' ) {
        $name = 'meio ambiente';
    }
    elsif ( $intent eq 'direitos_humanos' ) {
        $name = 'direitos humanos';
    }
    elsif ( $intent eq 'direitos_sociais' ) {
        $name = 'direitos sociais';
    }

    return $name;
}

sub extract_metrics {
    my ($self, %opts) = @_;

	$self = $self->search_rs( { 'me.created_at' => { '<=' => \"NOW() - interval '$opts{range}'" } } ) if $opts{range};

    my $most_significative_entity = $self->search(
        undef,
        { order_by => { -desc => 'recipient_count' } }
    )->first;

    return {
        # Contagem total de temas
		count             => $self->count,
		suggested_actions => [
			{
				alert             => '',
				alert_is_positive => 0,
				link              => '/temas',
				link_text         => 'Ver temas'
			},
		],
		sub_metrics => [
			# Métrica: o tema mais popular
			{
				text              => $most_significative_entity ? $most_significative_entity->name . ' é o seu tema mais popular' : undef,
				suggested_actions => []
			},
		]
	}
}

1;
