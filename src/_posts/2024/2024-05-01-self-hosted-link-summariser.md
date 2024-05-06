---
layout: post
title:  "Making a self hosted link summariser"
date:   2024-05-05 19:00:00 -0000
categories: [Golang, Go, APIs, ML, LLMs]
---

# Making a self hosted link summariser using LLMs

If you use Reddit or Lemmy you are likely to be familiar with those bots which summarise news links and comment the result. I decided to make one of these which uses an LLM to do the summarisation

## Step 1: Get the website's text

For this you want to get the page's HTML, and remove anything that won't help the bot such as javascript, CSS, images or videos. You'll also want to get rid of excessive spaces or newlines as they'll take up tokens that could be used for more words

```golang

func standardizeSpaces(s string) string {
	return strings.Join(strings.Fields(s), " ")
}

func scrapeSite(url string) (string, error) {
	resp, err := http.Get(url)
	if err != nil {
		slog.Error("Failed to get site", "site", url, "error", err)
		return "", err
	}
	defer resp.Body.Close()

	doc, err := goquery.NewDocumentFromReader(resp.Body)

	if err != nil {
		slog.Error("Failed to get site body", "site", url, "error", err)
		return "", err
	}

	doc.Find("img").Each(func(i int, el *goquery.Selection) {
		el.Remove()
	})
	// We don't care about images, we only want the text on the site
	doc.Find("picture").Each(func(i int, el *goquery.Selection) {
		el.Remove()
	})
	// We don't care about scripts, we only want the text on the site
	doc.Find("script").Each(func(i int, el *goquery.Selection) {
		el.Remove()
	})
	// We don't care about css, we only want the text on the site
	doc.Find("style").Each(func(i int, el *goquery.Selection) {
		el.Remove()
	})
	// We don't care about videos, we only want the text on the site
	doc.Find("video").Each(func(i int, el *goquery.Selection) {
		el.Remove()
	})

	// There's unlikely to be anything we want in these
	doc.Find("noscript").Each(func(i int, el *goquery.Selection) {
		el.Remove()
	})

	// remove excess newlines etc
	bdyText := standardizeSpaces(doc.Text())
	slog.Info(bdyText)
	return bdyText, err
}
```

## Step 2: Use the LLM to summarise the text

For this you'll need to truncate the content from the site if it's too long, and send it over to the LLM, with a prompt and "thought" that it should do this.

```golang

func doSummarisation(token string, maxTokens int, server string, model string, siteText string) (summary string, err error) {

	lengthOfDataToSend := len(siteText)

	// Just a rule of thumb
	likelyMaximumLengthAccepted := 2 * maxTokens
	if len(siteText) > 2*likelyMaximumLengthAccepted {
		lengthOfDataToSend = 2 * likelyMaximumLengthAccepted
	}

	aiClient := openai.DefaultConfig(token)
	aiClient.BaseURL = server
	client := openai.NewClientWithConfig(aiClient)

	stream, err := client.CreateChatCompletionStream(
		context.Background(),
		openai.ChatCompletionRequest{
			Model: model,
			Messages: []openai.ChatCompletionMessage{
				{Role: openai.ChatMessageRoleSystem,
					Content: "You are an expert at summarising text in a concise manner for intelligent social media users.",
				},
				{
					Role: openai.ChatMessageRoleUser,
					Content: fmt.Sprintf("Summarise the following text using the fewest possible words\n, %s",
						siteText[:lengthOfDataToSend-1]),
				},
			},
			Stream:           true,
			Stop:             []string{"<|end_of_text|>", "<|eot_id|>"},
			Temperature:      0.7,
			TopP:             0.95,
			MaxTokens:        maxTokens,
			FrequencyPenalty: 0.0,
			PresencePenalty:  0.0,
		},
	)

	if err != nil {
		slog.Error("Error with ChatCompletionStream for summariser", "error", err)
		return "", err
	}
	defer stream.Close()

	var summaryBuilder strings.Builder
	for {
		var response openai.ChatCompletionStreamResponse
		response, err = stream.Recv()
		if errors.Is(err, io.EOF) {
			slog.Debug("Finished receiving response from LLM")
			return summaryBuilder.String(), nil
		}

		if err != nil {
			slog.Error("Error with ChatCompletionStream for summariser", "error", err)
			return summaryBuilder.String(), err
		}
		_, err = summaryBuilder.WriteString(response.Choices[0].Delta.Content)

		if err != nil {
			slog.Error("Error with writing stream to summary", "error", err)
			return summaryBuilder.String(), err
		}

	}
	// Never get here

}

```

## The code

Full version of this code available at <https://github.com/RichardoC/personal-webpage-summariser>

Better versions exist such as <https://github.com/RikudouSage/LemmyAutoTldrBot>