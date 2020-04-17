from deoplete.source.base import Base

# @see https://microsoft.github.io/language-server-protocol/specification#textDocument_completion

COMPLETION_ITEM_KIND = [
    'Text',
    'Method',
    'Function',
    'Constructor',
    'Field',
    'Variable',
    'Class',
    'Interface',
    'Module',
    'Property',
    'Unit',
    'Value',
    'Enum',
    'Keyword',
    'Snippet',
    'Color',
    'File',
    'Reference',
    'Folder',
    'EnumMember',
    'Constant',
    'Struct',
    'Event',
    'Operator',
    'TypeParameter',
]

class Source(Base):
    def __init__(self, vim):
        Base.__init__(self, vim)

        self.name = 'lsc'
        self.mark = '[lsc]'
        self.rank = 500
        self.input_pattern = r'[^\w\s]$'
        self.vars = {}

    def gather_candidates(self, context):
        if not self.vim.call('deoplete_vim_lsc#is_completable'):
            context['is_async'] = False
            return[]

        request = self.vim.call('deoplete_vim_lsc#find_request', context['input'])
        if request:
            if request['response']:
                context['is_async'] = False
                return self.to_candidates(request['response'])
            return []
        else:
            context['is_async'] = True
            self.vim.call('deoplete_vim_lsc#request_completion', context['input'])
        return []

    def to_candidates(self, items):
        candidates = [{
            'word': item['insertText'] if item.get('insertText', None) else item['label'],
            'abbr': item['insertText'] if item.get('insertText', None) else item['label'],
            'menu': item['detail'] if item.get('detail', None) else item['label'],
            'info': item['detail'] if item.get('detail', None) else item['label'],
            'kind': COMPLETION_ITEM_KIND[item.get('kind', 1) - 1]
        } for item in items]
        return candidates

