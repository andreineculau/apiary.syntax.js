/*global Rainbow*/
/**
 * Apiary patterns
 *
 * @author Andrei Neculau <@andreineculau>
 * @version 1.0.0
 */
Rainbow.extend('apiary', [
    /**
     * method
     */
    {
        matches: {
            2: 'entity.function',
            3: 'entity.value'
        },
        pattern: /(^|\n)\s*(CONNECT|DELETE|GET|HEAD|OPTIONS|PATCH|POST|PUT|TRACE) (.*)/g
    },
    {
        matches: {
            1: 'entity.keyword',
            2: 'entity.variable',
            3: 'entity.value.string'
        },
        pattern: /\n\s*(<|&lt;|>|&gt;) ([\w\-]+): (.*)/g
    },
    {
        matches: {
            1: 'entity.keyword',
            2: 'entity.function',
            3: 'entity.class'
        },
        pattern: /\n\s*(<|&lt;) ([1-9][0-9]{2,2}) ?(.*)?/g
    }
]);
