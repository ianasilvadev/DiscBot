defmodule DiscBot do
  use Nostrum.Consumer
  alias Nostrum.Api
  alias HTTPoison

  @history_api_url "https://history.muffinlabs.com/date"
  @wiki_api_url "https://en.wikipedia.org/api/rest_v1/page/summary/"
  @restcountries_api_url "https://restcountries.com/v3.1/name/"

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    case msg.content do
      "!ping" -> Api.create_message(msg.channel_id, "pong!")
      "!fato" -> buscar_historico(msg.channel_id)
      "!pergunta" -> buscar_e_enviar_pergunta(msg.channel_id)
      "!personagem " <> nome_personagem -> buscar_e_enviar_info_personagem(nome_personagem, msg.channel_id)
      "!pais " <> nome_pais -> buscar_pais(nome_pais, msg.channel_id)
      "!bandeira " <> nome_pais -> bandeira_pais(nome_pais, msg.channel_id)
      _ -> :ignore
    end
  end

  defp buscar_historico(channel_id) do
    buscar_dados(@history_api_url)
    |> case do
      {:ok, body} -> enviar_resposta_historico(body, channel_id)
      {:error, reason} -> Api.create_message(channel_id, "Desculpe, ocorreu um erro ao buscar fatos históricos: #{reason}")
    end
  end

  defp buscar_e_enviar_pergunta(channel_id) do
    buscar_dados("https://opentdb.com/api.php?amount=1&type=multiple")
    |> case do
      {:ok, body} -> enviar_resposta_pergunta(body, channel_id)
      {:error, reason} -> Api.create_message(channel_id, "Desculpe, não consegui obter uma pergunta no momento: #{reason}")
    end
  end

  defp buscar_e_enviar_info_personagem(nome_personagem, channel_id) do
    url = @wiki_api_url <> URI.encode(nome_personagem)
    buscar_dados(url)
    |> case do
      {:ok, body} -> enviar_resumo_personagem(body, nome_personagem, channel_id)
      {:error, reason} -> Api.create_message(channel_id, "Desculpe, não consegui encontrar informações sobre #{nome_personagem}: #{reason}")
    end
  end

  defp buscar_pais(nome_pais, channel_id) do
    url = @restcountries_api_url <> URI.encode(nome_pais)
    buscar_dados(url)
    |> case do
      {:ok, body} -> enviar_info_pais(body, nome_pais, channel_id)
      {:error, reason} -> Api.create_message(channel_id, "Desculpe, não consegui encontrar informações sobre o país #{nome_pais}: #{reason}")
    end
  end

  defp buscar_dados(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> {:ok, body}
      {:ok, %HTTPoison.Response{status_code: status_code}} -> {:error, "Erro HTTP #{status_code}"}
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, "Erro de conexão: #{reason}"}
    end
  end

  defp enviar_resposta_historico(body, channel_id) do
    case Jason.decode(body) do
      {:ok, %{"data" => %{"Events" => events}}} ->
        event_list = Enum.take(events, 3)
                     |> Enum.map(&("#{&1["year"]}: #{&1["text"]}"))
                     |> Enum.join("\n")
        Api.create_message(channel_id, "Fatos históricos do dia:\n" <> event_list)

      _ -> Api.create_message(channel_id, "Desculpe, não consegui obter os eventos históricos.")
    end
  end

  defp enviar_resposta_pergunta(body, channel_id) do
    case Jason.decode(body) do
      {:ok, %{"results" => [dados_pergunta]}} ->
        pergunta = dados_pergunta["question"]
        respostas = [dados_pergunta["correct_answer"] | dados_pergunta["incorrect_answers"]] |> Enum.shuffle()
        mensagem = formatar_mensagem_pergunta(pergunta, respostas)
        Api.create_message(channel_id, mensagem)

      _ -> Api.create_message(channel_id, "Desculpe, não consegui obter uma pergunta.")
    end
  end

  defp formatar_mensagem_pergunta(pergunta, respostas) do
    answer_list = Enum.map_join(respostas, "\n", &("- " <> &1))
    "**Pergunta:**\n#{pergunta}\n**Respostas:**\n#{answer_list}"
  end

  defp enviar_resumo_personagem(body, nome_personagem, channel_id) do
    case Jason.decode(body) do
      {:ok, %{"extract" => resumo}} ->
        Api.create_message(channel_id, "**#{nome_personagem}**:\n" <> resumo)

      _ -> Api.create_message(channel_id, "Desculpe, não consegui encontrar informações sobre #{nome_personagem}.")
    end
  end

  defp enviar_info_pais(body, nome_pais, channel_id) do
    case Jason.decode(body) do
      {:ok, [dados_pais | _]} ->
        mensagem = formatar_info_pais(dados_pais)
        Api.create_message(channel_id, mensagem)

      _ -> Api.create_message(channel_id, "Desculpe, não consegui encontrar informações sobre o país #{nome_pais}.")
    end
  end

  defp formatar_info_pais(dados_pais) do
    nome = dados_pais["name"]["common"]
    capital = dados_pais["capital"] |> List.first() || "Não disponível"
    regiao = dados_pais["region"] || "Não disponível"
    populacao = dados_pais["population"] || "Não disponível"
    idiomas = dados_pais["languages"] |> Map.values() |> Enum.join(", ")

    """
    **Informações sobre #{nome}:**
    - Capital: #{capital}
    - Região: #{regiao}
    - População: #{populacao}
    - Idiomas: #{idiomas}
    """
  end

  defp bandeira_pais(nome_pais, channel_id) do
    url = @restcountries_api_url <> URI.encode(nome_pais)
    buscar_dados(url)
    |> case do
      {:ok, body} -> enviar_resposta_bandeira(body, nome_pais, channel_id)
      {:error, reason} -> Api.create_message(channel_id, "Desculpe, não consegui obter a bandeira do país #{nome_pais}: #{reason}")
    end
  end

  defp enviar_resposta_bandeira(body, nome_pais, channel_id) do
    case Jason.decode(body) do
      {:ok, [dados_pais | _]} ->
        url_bandeira = dados_pais["flags"]["png"]
        mensagem = "Aqui está a bandeira do país #{nome_pais}:\n#{url_bandeira}"
        Api.create_message(channel_id, mensagem)

      _ -> Api.create_message(channel_id, "Desculpe, não consegui encontrar informações sobre o país #{nome_pais}.")
    end
  end
end
