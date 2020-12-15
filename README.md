# lua-simple-db

Using 5.3 features, use binary files to store a data to the filesystem like a database. This will be designed as a simple implementation with little data constraints (for now).

## Structure

### Column Types `col-type`

[Loosely based off the order of this](https://www.lua.org/manual/5.3/manual.html#6.4.2)
```
xxxx0000 = null termination
xxxx0001 = boolean
xxxx0010 = signed byte (char)
xxxx0011 = unsigned byte (char)
xxxx0100 = signed short (native size)
xxxx0101 = unsigned short (native size) [short record-id]
xxxx0110 = signed long (native size)
xxxx0111 = unsigned long (native size) [long record-id]
xxxx1000 = float (native size)
xxxx1001 = double (native size)
xxxx1010 = char string (char size, utf8 string)
xxxx1011 = short string (short size, utf8 string)
xxxx1100 = long string (long size, utf8 string)
[...]
xxxx1111 = reserved
```
`record-id` are used when describing the kind of Record ID to use.

### Main database file `db-name.db`

#### Table Definition

Describes the table so decoding method is known and columns are named appropriately in responses. A record id type **must** be first.

Table is described in the following format, then null terminated to indicate end of the definition.

```
[col-type; record-id-type][col-type][utf8; col-name][... columns][null byte]
```

**Note:** Record ID `0` is reserved for null records

After the definition, each record gets it's id followed by it's binary representation. So if the definition describes a short row-id, long, short, and a short string then a short row-id (2 bytes), long (4 bytes), short (2 bytes), short (2 bytes), then the utf8 data of a string will be written.

#### Data types

Most of the types follow the specificiation [here](https://www.lua.org/manual/5.3/manual.html#6.4.2), so a short or a long follow the same kind of specification in the manual (2 byte, 4 byte respectively as example.)

##### Boolean

```
xxxxxxx0 = false
xxxxxxx0 = true
```

##### Strings

Basically pascal strings; their size described followed by utf8 data afterwards.

### Index files `db-name.col-name.idx`

These files are used to speed up lookup and are simply a long binary stream of offsets and the column's data.

```
[long; offset][???; data]
```

**Note:** offset `0` is used whenever a index has been removed.

## Data handling

### Addition

New records are appended to the end of the file and associated index files are appended. For fixed size record databases, finding the next free space could be done if the penalty of locating one is not an issue.

### Modification

* Record at end of file
    * Update record in place, update indexes
* Record middle of file
  * Record length is fixed (no variable strings)
    * Update record in place, update indexes
  * Record length is variable (variable strings)
    * Write new version of record to end of file, use `0` for the Record ID in the old location; write new index at end of index file, use `0` for offset in old location

### Removal

* Record at end of file
  * File truncated, index truncated
* Record middle of file
  * Record ID set to `0`, index offset set to `0`

### Maintenance

Since updating records for a database of variably sized records will eventually leave a lot of unused space, occasionally rewriting the database files are required. This implementation will read the first valid record to before the next null record, shift that range down, and repeat.

This logic also applies to indexes.

# Example
```
[Record 1] ==> [Record 1] ==> [Record 1] ==> [Record 1]
[Record X]     [Record 3]     [Record 3]     [Record 3]
[Record 3]     [Record 4]     [Record 4]     [Record 4]
[Record 4]     [Record 4]     [Record 7]     [Record 7]
[Record X]     [Record X]     [Record X]
[Record X]     [Record X]     [Record X]
[Record 7]     [Record 7]     [Record 7]
```
Since the first record is already at the beginning of the records, it will stay in place. So find the first null record, read the next valid record (3), then read until finding the next null record (after 4), deduce the range containing the valid records, and move that range down.
```
[Record 1]
[Record 3]
[Record 4]
[Record 4]
[Record X]
[Record X]
[Record 7]
```
Read to the next valid record (7), next invalid record (EOF, after 7), move the valid range down.
```
[Record 1]
[Record 3]
[Record 4]
[Record 7]
[Record X]
[Record X]
[Record 7]
```
At EOF, truncate file after the moved range.
```
[Record 1]
[Record 3]
[Record 4]
[Record 7]
```

## Possible additions

* Binary tree for index, or attempt to store values sorted
