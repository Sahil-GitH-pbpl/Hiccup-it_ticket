from fastapi.templating import Jinja2Templates


class CompatJinja2Templates(Jinja2Templates):
    def TemplateResponse(self, *args, **kwargs):  # noqa: N802
        if len(args) >= 2 and isinstance(args[0], str) and isinstance(args[1], dict):
            name = args[0]
            context = args[1]
            request = context.get("request")
            if request is None:
                raise ValueError("Template context must include request")
            remaining_args = args[2:]
            return super().TemplateResponse(request, name, context, *remaining_args, **kwargs)
        return super().TemplateResponse(*args, **kwargs)
