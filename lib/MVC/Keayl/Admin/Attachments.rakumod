use v6.d;
use MVC::Keayl::Storage;
use MVC::Keayl::Storage::Attached;

unit class MVC::Keayl::Admin::Attachments;

# File-upload fields are stored through Active Storage's repository and service
# keyed by the record's type, id, and the field name. This works for any ORM
# model without composing the storage role onto it (which would collide with the
# ORM's own attribute dispatch).

method attach(::?CLASS:U: $record, Str:D $name, %upload --> Nil) {
  # Replace any existing attachment for this field. attachment-for serves the
  # first attachment, so re-uploading without removing the old one leaves the
  # original in place and the new file is never shown.
  self.detach($record, $name);

  my $data = %upload<content>;
  my $blob = MVC::Keayl::Storage::Blob.build($data, filename => %upload<filename>, content-type => %upload<type>);

  storage-repository.create-blob($blob);
  storage-service.upload($blob.key, $data);

  storage-repository.create-attachment(MVC::Keayl::Storage::Attachment.new(
    name        => $name,
    record-type => $record.WHAT.^name,
    record-id   => $record.id,
    blob        => $blob,
  ));
}

# Remove every attachment for this record and field, purging each one's blob
# (stored bytes and blob record) so a re-upload leaves no orphans behind.
method detach(::?CLASS:U: $record, Str:D $name --> Nil) {
  for storage-repository.attachments-for($record.WHAT.^name, $record.id, $name) -> $attachment {
    with $attachment.blob -> $blob {
      storage-service.delete($blob.key);
      storage-repository.delete-blob($blob);
    }
    storage-repository.delete-attachment($attachment);
  }
  Nil
}

method attachment-for(::?CLASS:U: $record, Str:D $name) {
  storage-repository.attachments-for($record.WHAT.^name, $record.id, $name).first
}
