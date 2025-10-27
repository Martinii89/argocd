{{- define "dummy-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "dummy-app.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "dummy-app.labels" -}}
helm.sh/chart: {{ include "dummy-app.chart" . }}
app.kubernetes.io/name: {{ include "dummy-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "dummy-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dummy-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "dummy-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "dummy-app.previewPage" -}}
{{- $ctx := . -}}
<!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="utf-8" />
		<meta http-equiv="X-UA-Compatible" content="IE=edge" />
		<meta name="viewport" content="width=device-width, initial-scale=1" />
		{{- if $ctx.refresh }}
		<meta http-equiv="refresh" content="{{ $ctx.refresh }}" />
		{{- end }}
		<title>{{ $ctx.title | html }}</title>
		{{- with $ctx.description }}
		<meta name="description" content="{{ . | html }}" />
		{{- end }}
		{{- with $ctx.color }}
		<meta name="theme-color" content="{{ . | html }}" />
		{{- end }}
		{{- with $ctx.siteName }}
		<meta property="og:site_name" content="{{ . | html }}" />
		{{- end }}
		<meta property="og:title" content="{{ $ctx.title | html }}" />
		{{- with $ctx.description }}
		<meta property="og:description" content="{{ . | html }}" />
		{{- end }}
		{{- with $ctx.url }}
		<meta property="og:url" content="{{ . | html }}" />
		{{- end }}
		{{- with $ctx.imageUrl }}
		<meta property="og:image" content="{{ . | html }}" />
		{{- with $ctx.imageAlt }}
		<meta property="og:image:alt" content="{{ . | html }}" />
		{{- end }}
		{{- end }}
		<meta name="twitter:card" content="{{ $ctx.twitterCard | html }}" />
		<meta name="twitter:title" content="{{ $ctx.title | html }}" />
		{{- with $ctx.description }}
		<meta name="twitter:description" content="{{ . | html }}" />
		{{- end }}
		{{- with $ctx.imageUrl }}
		<meta name="twitter:image" content="{{ . | html }}" />
		{{- end }}
		{{- with $ctx.imageAlt }}
		<meta name="twitter:image:alt" content="{{ . | html }}" />
		{{- end }}
		{{- range $ctx.additionalMeta }}
		{{ . }}
		{{- end }}
	</head>
	<body>
		<main>
			<h1>{{ $ctx.title | html }}</h1>
			{{- with $ctx.description }}
			<p>{{ . | html }}</p>
			{{- end }}
			{{- with $ctx.url }}
			<p><a href="{{ . | html }}">Continue to the site</a></p>
			{{- end }}
		</main>
	</body>
</html>
{{- end -}}
