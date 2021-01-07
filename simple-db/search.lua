local search = {}

function search.exact(value)
    return function (test)
        return value == test
    end
end

function search.match(pattern)
    return function (test)
        return string.match(test, pattern) ~= nil
    end
end

function search.range(from, to)
    return function (test)
        return test >= from and test <= to
    end
end

return search