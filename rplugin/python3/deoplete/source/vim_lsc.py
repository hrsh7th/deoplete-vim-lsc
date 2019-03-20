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

        if self.vim.call('deoplete_vim_lsc#match_context', context, self.vim.vars['deoplete_vim_lsc#request']['context']):
            if self.vim.vars['deoplete_vim_lsc#request']['responsed']:
                context['is_async'] = False
                return self.to_candidates(self.vim.vars['deoplete_vim_lsc#request']['response'])
            return []
        else:
            context['is_async'] = True
            self.vim.call('deoplete_vim_lsc#request_completion', context)
        return []

    def to_candidates(self, items):
        candidates = [{
            'word': item['insertText'] if item.get('insertText', None) else item['label'],
            'abbr': item['insertText'] if item.get('insertText', None) else item['label'],
            'kind': COMPLETION_ITEM_KIND[item['kind'] - 1]
        } for item in items]
        return candidates

