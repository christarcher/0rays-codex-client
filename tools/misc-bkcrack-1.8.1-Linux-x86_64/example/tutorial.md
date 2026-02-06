Tutorial {#tutorial}
========

\brief A guide to crack an example encrypted zip file.

The `example` folder contains an example zip file `secrets.zip` so you can run an attack.
Its content is probably of great interest!

# What is inside

Let us see what is inside.
Open a terminal in the `example` folder and run this command.

    $ ../bkcrack -L secrets.zip

We get the following output.

    Archive: secrets.zip
    Index Encryption Compression CRC32    Uncompressed  Packed size Name
    ----- ---------- ----------- -------- ------------ ------------ ----------------
        0 ZipCrypto  Deflate     7ca9f10a        54799        54700 advice.jpg
        1 ZipCrypto  Store       a99f1d0d         1265         1277 spiral.svg

So the zip file contains two entries: `advice.jpg` and `spiral.svg`.
They are both encrypted with traditional PKWARE encryption denoted as ZipCrypto.
We also see that `advice.jpg` is deflated whereas `spiral.svg` is stored uncompressed.

# Guessing plaintext

To run the attack, we must guess at least 12 bytes of plaintext.
On average, the more plaintext we guess, the faster the attack will be.

## The easy way: stored file

We can guess from its extension that `spiral.svg` probably starts with the string `<?xml version="1.0" `.

We are so lucky that this file is stored uncompressed in the zip file.
So we have 20 bytes of plaintext, which is more than enough.

## The not so easy way: deflated file

Let us assume the zip file did not contain the uncompressed `spiral.svg`.

Then, to guess some plaintext, we can guess the first bytes of the original `advice.jpg` file from its extension.
The problem is that this file is compressed.
To run the attack, one would have to guess how those first bytes are compressed, which is difficult without knowing the entire file.

In this example, this approach is not practical.
It can be practical if the original file can easily be found online, like a .dll file for example.
Then, one would compress it using various compression software and compression levels to try and generate the correct plaintext.

## Free additional check byte

As explained in the ZIP file format specification, each entry's data is prepended by a 12-byte header before encryption.
This encryption header starts with random bytes, but the last byte can be inferred from the entry's metadata.
The purpose of this check byte is to test if the password supplied appears to be correct or not when trying to extract an encrypted entry without having to process the encrypted and potentially compressed data further.

This check byte is automatically added to the known plaintext when bkcrack loads ciphertext from an archive.
So overall, we know 21 bytes of plaintext in this example: we guessed 20 bytes and the check byte is added automatically.

# Running the attack

Let us write the plaintext we guessed in a file. Notice the `-n` flag not to output a trailing newline character.

    $ echo -n '<?xml version="1.0" ' > plain.txt

We are now ready to run the attack.

    $ ../bkcrack -C secrets.zip -c spiral.svg -p plain.txt

After a little while, the keys will appear!

    [17:42:43] Z reduction using 13 bytes of known plaintext
    100.0 % (13 / 13)
    [17:42:44] Attack on 542303 Z values at index 6
    Keys: c4490e28 b414a23d 91404b31
    33.9 % (183750 / 542303)
    Found a solution. Stopping.
    You may resume the attack with the option: --continue-attack 183750
    [17:48:03] Keys
    c4490e28 b414a23d 91404b31

# Recovering the original files

Once we have the keys, we can recover the original files.

## Remove the password

We assume that the same keys were used for all the files in the zip file.
We can create a new archive based on `secrets.zip`, but without password protection.

    $ ../bkcrack -C secrets.zip -k c4490e28 b414a23d 91404b31 -D secrets_without_password.zip

Then, any zip file utility can extract the created archive.

## Choose a new password

We can also create a new encrypted archive, but with a new password, `easy` in this example.

    $ ../bkcrack -C secrets.zip -k c4490e28 b414a23d 91404b31 -U secrets_with_new_password.zip easy

Then, you will just have to type the chosen password when prompted to extract the created archive.

## Or decipher files

Alternatively, we can decipher files one by one.

    $ ../bkcrack -C secrets.zip -c spiral.svg -k c4490e28 b414a23d 91404b31 -d spiral_deciphered.svg

The file `spiral.svg` was stored uncompressed so we are done.

    $ ../bkcrack -C secrets.zip -c advice.jpg -k c4490e28 b414a23d 91404b31 -d advice_deciphered.deflate

The file `advice.jpg` was compressed with the deflate algorithm in the zip file, so we now have to uncompressed it.

A python script is provided for this purpose in the `tools` folder.

    $ python3 ../tools/inflate.py < advice_deciphered.deflate > very_good_advice.jpg

You can now open `very_good_advice.jpg` and enjoy it!

# Recovering the original password

As shown above, the original password is not required to decrypt data.
The internal keys are enough.
However, we might also be interested in finding the original password.

## Bruteforce password recovery

To do this, we need to choose a maximum length and a set of characters among which we hope to find those that constitute the password.
To save time, we have to choose those parameters wisely.
For a given length, a small charset will be explored much faster than a big one, but making a wrong assumption by choosing a charset that is too small will not allow to recover the password.

At first, we can try all candidates up to a given length without making any assumption about the character set.
We use the charset `?b` which is the set containing all bytes (from 0 to 255), so we do not miss any candidate up to length 9.

    $ ../bkcrack -k c4490e28 b414a23d 91404b31 --bruteforce ?b --length 0..9

    [17:52:16] Recovering password
    length 0-6...
    length 7...
    length 8...
    length 9...
    [17:52:16] Could not recover password

It failed so we know the password has 10 characters or more.

Now, let us assume the password is made of 10 or 11 printable ASCII characters, using the charset `?p`.

    $ ../bkcrack -k c4490e28 b414a23d 91404b31 --bruteforce ?p --length 10..11

    [17:52:34] Recovering password
    length 10...
    length 11...
    100.0 % (9025 / 9025)
    [17:52:38] Could not recover password

It failed again so we know the password has non-printable ASCII characters or has 12 or more characters.

Now, let us assume the password is made of 12 alpha-numerical characters.

    $ ../bkcrack -k c4490e28 b414a23d 91404b31 --bruteforce ?a --length 12

    [17:54:37] Recovering password
    length 12...
    Password: W4sF0rgotten
    51.7 % (1989 / 3844)
    Found a solution. Stopping.
    You may resume the password recovery with the option: --continue-recovery 573478303030
    [17:54:49] Password
    as bytes: 57 34 73 46 30 72 67 6f 74 74 65 6e
    as text: W4sF0rgotten

Tada! We made the right assumption for this case.
The password was recovered quickly from the keys.

## Mask-based password recovery

This case was easy enough, but some passwords are too long for bruteforce to be viable.
For such long passwords, it is worth trying to restrict the search space.
Instead of using the same charset to draw all characters, we can specify a charset for each character in the password.
This sequence of charsets is the mask.
The mask must be chosen carefully to be large enough to contain the password but small enough to be explored in a reasonable amount of time.

Here is an example.
Assume a known-plaintext attack gave us the keys `b8c377a6 f603160f 1832a78b`.
Now we want to find the password.
Lucky for us, we remember vaguely that our password is made of 10 letters (uppercase or lowercase) and 5 binary digits.

Recovering the password with bruteforce could take *days*:

    $ ../bkcrack -k b8c377a6 f603160f 1832a78b --bruteforce ?u?l01 --length 15

Instead, we can take advantage of our partial knowledge of the password to significantly narrow down the search space:

    $ ../bkcrack -k b8c377a6 f603160f 1832a78b --mask ?x?x?x?x?x?x?x?x?x?x?y?y?y?y?y -s x ?u?l -s y 01

    [17:56:08] Recovering password
    Password: VerySecret01011
    82.9 % (1379 / 1664)
    Found a solution. Stopping.
    You may resume the password recovery with the option: --continue-recovery 313130313062414141
    [17:56:08] Password
    as bytes: 56 65 72 79 53 65 63 72 65 74 30 31 30 31 31
    as text: VerySecret01011

This command searches for a password where the first 10 characters are from charset `?x` (a custom charset defined as `?u?l` for uppercase or lowercase letters) and the next 5 characters are from charset `?y` (a custom charset defined as `01` for binary digits).
In this example, restricting the search space that way makes the recovery run and find the password in milliseconds.
